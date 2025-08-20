import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart'; // To use AuthGate or any next screen

class IntroductionScreens extends StatelessWidget {
  const IntroductionScreens({Key? key}) : super(key: key);

  Future<void> _completeIntroduction(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('intro_seen', true);

    // Navigate to AuthGate (replace this with LoginScreen or WelcomeScreen if needed)
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthGate()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IntroductionScreen(
        pages: [
          PageViewModel(
            title: 'Convenience',
            body:
                'Control your home device\nusing a single app\nfrom anywhere in the world',

            image: buildImage("assets/Rectangle_1.jpg"),
            decoration: getPageDecoration(),
          ),
          PageViewModel(
            title: 'Automate',
            body:
                'Switch through different scenes\nand quick actions for fast\nmanagement of your home',
            image: buildImage("assets/Rectangle_2.jpg"),
            decoration: getPageDecoration(),
          ),
          PageViewModel(
            title: 'Stay informed',
            body: 'Get instant notifications\nabout any activity or alerts',
            image: buildImage("assets/Rectangle_3.jpg"),
            decoration: getPageDecoration(),
          ),
        ],
        onDone: () => _completeIntroduction(context),
        onSkip: () => _completeIntroduction(context),
        scrollPhysics: const ClampingScrollPhysics(),
        showDoneButton: true,
        showNextButton: true,
        showSkipButton: true,
        skip: const Text(
          "Skip",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFFFF9900),
          ),
        ),
        next: const Text(
          "Next",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFFFF9900),
          ),
        ),
        done: const Text(
          "Done",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFFFF9900),
          ),
        ),
        dotsDecorator: getDotsDecorator(),
      ),
    );
  }

  Widget buildImage(String imagePath) {
    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Image.asset(imagePath, fit: BoxFit.contain),
    );
  }

  PageDecoration getPageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      bodyTextStyle: TextStyle(fontSize: 14, color: Colors.black54),
      imagePadding: EdgeInsets.only(top: 60),
      contentMargin: EdgeInsets.symmetric(horizontal: 16),
      pageColor: Colors.white,
    );
  }

  DotsDecorator getDotsDecorator() {
    return const DotsDecorator(
      spacing: EdgeInsets.symmetric(horizontal: 2),
      activeColor: Color(0xFFFF9900),
      color: Colors.grey,
      activeSize: Size(12, 5),
      activeShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(25.0)),
      ),
    );
  }
}
