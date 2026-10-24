/**
 * Upstash Redis Client for Firebase Cloud Functions / Node Backend
 * Manages real-time User and Driver actions via Upstash REST API
 */

const https = require('https');
const url = require('url');

class UpstashRedisClient {
  constructor() {
    this.restUrl = process.env.UPSTASH_REDIS_REST_URL || 'https://darling-cow-289945.upstash.io';
    this.restToken = process.env.UPSTASH_REDIS_REST_TOKEN || 'gQAAAAAABGyZAAIgcDI0NzU2NWE5YzdlY2I0ZWI3OWVmMWM1NzZhYjM2ZjkwNw';
  }

  exec(commandArray) {
    return new Promise((resolve, reject) => {
      if (!this.restUrl || !this.restToken) {
        return resolve(null);
      }

      const parsedUrl = url.parse(this.restUrl);
      const postData = JSON.stringify(commandArray);

      const options = {
        hostname: parsedUrl.hostname,
        port: parsedUrl.port || 443,
        path: parsedUrl.pathname || '/',
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.restToken}`,
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData)
        }
      };

      const req = https.request(options, (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            resolve(parsed.result);
          } catch (e) {
            resolve(null);
          }
        });
      });

      req.on('error', (e) => {
        console.warn('Upstash Redis error:', e.message);
        resolve(null);
      });

      req.write(postData);
      req.end();
    });
  }

  async pipeline(commands) {
    return new Promise((resolve, reject) => {
      const parsedUrl = url.parse(this.restUrl + '/pipeline');
      const postData = JSON.stringify(commands);

      const options = {
        hostname: parsedUrl.hostname,
        port: parsedUrl.port || 443,
        path: parsedUrl.pathname,
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${this.restToken}`,
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(postData)
        }
      };

      const req = https.request(options, (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          try {
            const parsed = JSON.parse(data);
            resolve(parsed.map(item => item.result));
          } catch (e) {
            resolve([]);
          }
        });
      });

      req.on('error', (e) => {
        resolve([]);
      });

      req.write(postData);
      req.end();
    });
  }

  async setDriverLocation(driverId, lat, lng, heading = 0, speed = 0) {
    const nowIso = new Date().toISOString();
    const locKey = `driver:location:${driverId}`;
    return this.pipeline([
      ['HSET', locKey, 'latitude', String(lat), 'longitude', String(lng), 'heading', String(heading), 'speed', String(speed), 'updatedAt', nowIso],
      ['EXPIRE', locKey, 3600],
      ['GEOADD', 'drivers:geo', lng, lat, driverId]
    ]);
  }

  async setDriverStatus(driverId, isOnline) {
    const nowIso = new Date().toISOString();
    const statusKey = `driver:status:${driverId}`;
    const cmds = [
      isOnline ? ['SADD', 'drivers:online', driverId] : ['SREM', 'drivers:online', driverId],
      ['HSET', statusKey, 'isOnline', isOnline ? '1' : '0', 'updatedAt', nowIso],
      ['EXPIRE', statusKey, 86400]
    ];
    return this.pipeline(cmds);
  }

  async logAction(entityType, entityId, actionType, details = {}) {
    const key = `activity:${entityType}:${entityId}`;
    const logEntry = JSON.stringify({
      entityType,
      entityId,
      action: actionType,
      details,
      timestamp: new Date().toISOString()
    });
    return this.pipeline([
      ['LPUSH', key, logEntry],
      ['LTRIM', key, 0, 49],
      ['EXPIRE', key, 604800]
    ]);
  }

  async cacheUser(userId, userData) {
    return this.exec(['SET', `user:profile:${userId}`, JSON.stringify(userData), 'EX', 86400]);
  }

  async cacheDriver(driverId, driverData) {
    return this.exec(['SET', `driver:profile:${driverId}`, JSON.stringify(driverData), 'EX', 86400]);
  }

  async cacheRide(rideId, rideData) {
    return this.exec(['SET', `ride:active:${rideId}`, JSON.stringify(rideData), 'EX', 7200]);
  }
}

module.exports = new UpstashRedisClient();
