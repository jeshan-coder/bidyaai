import 'package:anticipatorygpt/routers.dart';
import 'package:anticipatorygpt/theme.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // CHANGE: Explicitly setting the background to white to match the design.
      backgroundColor: Colors.white,
      // Using SafeArea to avoid notches and system UI elements
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            // Using spaceBetween to push the button to the bottom
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // This flexible container allows the top content to take available space
              Flexible(
                // CHANGE: Removed the centering alignment to push content to the top.
                child: Column(
                  children: [
                    // Added some space from the top of the screen.
                    const SizedBox(height: 40),
                    // --- IMPORTANT ---
                    // Make sure you add your image to 'assets/images/'
                    // and declare it in your pubspec.yaml file.
                    Image.asset(
                      'assets/assist.png',
                      height: MediaQuery.of(context).size.height * 0.4,
                    ),
                    const SizedBox(height: 48),
                    Text(
                      "BidyaAI",
                      style: textTheme.titleLarge?.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Education for unreachable",
                      style: textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // This is the bottom button
              Padding(
                padding: const EdgeInsets.only(bottom: 32.0, top: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    // This is the original navigation logic from your old button
                    Navigator.of(context).pushNamed(AppRoutes.chat);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56), // Full width
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: Text(
                    'Start Exploring',
                    style: textTheme.bodyMedium
                        ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
