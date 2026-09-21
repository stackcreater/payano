import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OnboardingSlide {
  final String titleStart;
  final String titleAccent;
  final String titleEnd;
  final String description;
  final IconData illustrationIcon;
  final IconData? badge1;
  final IconData? badge2;

  const _OnboardingSlide({
    required this.titleStart,
    required this.titleAccent,
    required this.titleEnd,
    required this.description,
    required this.illustrationIcon,
    this.badge1,
    this.badge2,
  });
}

const List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    titleStart: 'Safe rides to and\nfrom ',
    titleAccent: 'college',
    titleEnd: '',
    description:
        'Book safe, affordable rides with verified\nstudents travelling to and from college.',
    illustrationIcon: Icons.two_wheeler,
    badge1: Icons.verified_user,
    badge2: Icons.school,
  ),
  _OnboardingSlide(
    titleStart: 'Affordable rides at\nyour ',
    titleAccent: 'fingertips',
    titleEnd: '',
    description:
        'Transparent fares with Lite, Moto, and\nGreen EV options starting at just ₹15.',
    illustrationIcon: Icons.electric_bike,
    badge1: Icons.attach_money,
    badge2: Icons.bolt,
  ),
  _OnboardingSlide(
    titleStart: 'Track your ride in\n',
    titleAccent: 'real-time',
    titleEnd: '',
    description:
        'Live GPS tracking with verified drivers\nand one-tap SOS safety features.',
    illustrationIcon: Icons.location_on,
    badge1: Icons.my_location,
    badge2: Icons.shield,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late AnimationController _illustrationController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(
          parent: _illustrationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _illustrationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
  }

  void _nextPage() {
    if (_currentIndex < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _markOnboardingDone().then((_) => context.go('/login'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.two_wheeler,
                            size: 20, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Payano',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      _markOnboardingDone().then((_) => context.go('/login'));
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentIndex = i),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return _SlideContent(
                    slide: _slides[index],
                    floatAnimation: _floatAnimation,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentIndex == i ? 22 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == i
                              ? const Color(0xFF2563EB)
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        height: 52,
                        width: 140,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentIndex == _slides.length - 1
                                    ? 'Start'
                                    : 'Next',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  final _OnboardingSlide slide;
  final Animation<double> floatAnimation;

  const _SlideContent({
    required this.slide,
    required this.floatAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final circleSize = (constraints.maxWidth * 0.72).clamp(100.0, constraints.maxHeight * 0.45);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.25,
                    letterSpacing: -0.5,
                  ),
                  children: [
                    TextSpan(text: slide.titleStart),
                    TextSpan(
                      text: slide.titleAccent,
                      style: const TextStyle(color: Color(0xFF2563EB)),
                    ),
                    TextSpan(text: slide.titleEnd),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                slide.description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              Center(
                child: AnimatedBuilder(
                  animation: floatAnimation,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, floatAnimation.value),
                    child: child,
                  ),
                  child: Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE8EFF8),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          slide.illustrationIcon,
                          size: circleSize * 0.45,
                          color: const Color(0xFF2563EB),
                        ),
                        if (slide.badge1 != null)
                          Positioned(
                            top: circleSize * 0.15,
                            right: circleSize * 0.12,
                            child: _BadgeIcon(icon: slide.badge1!),
                          ),
                        if (slide.badge2 != null)
                          Positioned(
                            bottom: circleSize * 0.15,
                            left: circleSize * 0.12,
                            child: _BadgeIcon(icon: slide.badge2!),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  const _BadgeIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withAlpha(40),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF2563EB)),
    );
  }
}
