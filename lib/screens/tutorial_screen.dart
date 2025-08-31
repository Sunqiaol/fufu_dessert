import 'package:flutter/material.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  final List<TutorialStep> _tutorialSteps = [
    TutorialStep(
      title: 'Welcome to Fufu Dessert! 🍰',
      description: 'Welcome to your very own dessert café! In this game, you\'ll merge ingredients, craft delicious desserts, and serve happy customers.',
      icon: '🎉',
      imagePath: null,
    ),
    TutorialStep(
      title: 'The Merge Grid 🌾',
      description: 'This 5×7 grid is where the magic happens! You\'ll see base ingredients like Flour, Sugar, Milk, and more appearing here.',
      icon: '📦',
      imagePath: null,
      tips: ['Grid contains 35 cells for ingredients', 'New ingredients appear automatically', 'Each ingredient has a level (1-10)'],
    ),
    TutorialStep(
      title: 'How to Merge ✨',
      description: 'Tap 3 identical ingredients to merge them into a better ingredient! For example: 3 Flour (Level 1) → 1 Sugar (Level 2)',
      icon: '🔄',
      imagePath: null,
      tips: ['Must tap exactly 3 identical ingredients', 'They upgrade to the next level automatically', 'Higher levels = more valuable!'],
    ),
    TutorialStep(
      title: 'Base Ingredients (Levels 1-10) 🥚',
      description: 'There are 10 base ingredient levels you can merge through:\n\n🌾 Flour → 🍬 Sugar → 🥛 Milk → 🧈 Butter → 🥚 Eggs → 🍫 Chocolate → 🍓 Strawberries → 🌟 Vanilla → 🍦 Cream → 🍯 Honey',
      icon: '📊',
      imagePath: null,
      tips: ['Start with basic ingredients like Flour', 'Merge to get premium ingredients like Honey', 'Each level is worth more coins!'],
    ),
    TutorialStep(
      title: 'Sell Mode 💰',
      description: 'Click "Sell Mode" to select ingredients you want to store. Selected ingredients get a green glow. Then click "Store" to move them to your storage.',
      icon: '💸',
      imagePath: null,
      tips: ['Green glow = selected for storage', 'You can select multiple ingredients', 'Stored ingredients can be served to customers'],
    ),
    TutorialStep(
      title: 'Your Storage 📦',
      description: 'The Storage screen has two tabs:\n• "Merged Desserts" - Your base ingredients\n• "Crafted Desserts" - Complex recipes you\'ve made',
      icon: '🏪',
      imagePath: null,
      tips: ['Check storage often to see what you have', 'Customers want items from your storage', 'More storage = more serving options'],
    ),
    TutorialStep(
      title: 'Crafting System 👩‍🍳',
      description: 'Use the "Craft" button to make complex desserts! Combine multiple ingredients following recipes like:\n• Cookies = Flour + Sugar + Butter\n• Cupcake = Flour + Sugar + Eggs + Vanilla',
      icon: '🍪',
      imagePath: null,
      tips: ['10 different dessert recipes available', 'Need specific ingredients for each recipe', 'Crafted desserts are worth MUCH more!'],
    ),
    TutorialStep(
      title: 'Sample Recipes 📋',
      description: 'Here are some recipes to get you started:\n\n🍪 Cookies: Flour + Sugar + Butter\n🧁 Cupcake: Flour + Sugar + Eggs + Vanilla\n🥞 Pancakes: Flour + Milk + Eggs + Honey\n🎂 Rainbow Cake: ALL 10 ingredients!',
      icon: '📝',
      imagePath: null,
      tips: ['Start with simple 3-ingredient recipes', 'Rainbow Cake is the ultimate challenge', 'More ingredients = higher value'],
    ),
    TutorialStep(
      title: 'Serving Customers 🐻',
      description: 'Customers will appear in your café with orders! They want either:\n• Merged Desserts (from your ingredient storage)\n• Crafted Desserts (from your recipe crafting)',
      icon: '👥',
      imagePath: null,
      tips: ['70% want merged ingredients', '30% want crafted desserts', 'Serve quickly before they get impatient!'],
    ),
    TutorialStep(
      title: 'Customer Orders 📝',
      description: 'Look for customer order descriptions:\n• "🌾 Flour (Merged)" = wants Level 1 ingredient\n• "🍪 Cookies (Crafted)" = wants crafted dessert\n\nTap customers to serve them!',
      icon: '📋',
      imagePath: null,
      tips: ['Check what each customer wants', 'Make sure you have it in storage', 'Happy customers = more coins!'],
    ),
    TutorialStep(
      title: 'Café Management 🏠',
      description: 'Switch to the "Café" tab to:\n• See customers walking around\n• Manage your café layout\n• Serve customers directly by tapping them',
      icon: '🏢',
      imagePath: null,
      tips: ['Customers need tables to sit', 'Impatient customers leave quickly', 'Good service = higher profits'],
    ),
    TutorialStep(
      title: 'Game Strategy 🎯',
      description: 'Winning Tips:\n• Merge ingredients regularly to get higher levels\n• Keep a variety in storage for different customers\n• Focus on crafting valuable desserts\n• Serve customers quickly for maximum profit!',
      icon: '💡',
      imagePath: null,
      tips: ['Balance merging and storing', 'Craft expensive desserts for big profits', 'Don\'t let customers wait too long'],
    ),
    TutorialStep(
      title: 'Ready to Start! 🚀',
      description: 'You now know everything to run your dessert café successfully!\n\nRemember: Merge → Store → Craft → Serve → Profit!\n\nGood luck, and have fun building your dessert empire!',
      icon: '🎊',
      imagePath: null,
      tips: ['Start simple and experiment', 'Check the tutorial anytime from Settings', 'Most importantly - have fun!'],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _tutorialSteps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToStep(int step) {
    setState(() {
      _currentStep = step;
    });
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4E6),
      appBar: AppBar(
        title: const Text('Tutorial'),
        backgroundColor: const Color(0xFFFFE4E1),
        foregroundColor: Colors.brown[700],
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Skip',
              style: TextStyle(
                color: Colors.brown[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of ${_tutorialSteps.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[700],
                      ),
                    ),
                    Text(
                      '${(((_currentStep + 1) / _tutorialSteps.length) * 100).round()}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.brown[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (_currentStep + 1) / _tutorialSteps.length,
                  backgroundColor: Colors.brown[100],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.brown[400]!),
                  minHeight: 6,
                ),
              ],
            ),
          ),
          
          // Tutorial content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              itemCount: _tutorialSteps.length,
              itemBuilder: (context, index) {
                final step = _tutorialSteps[index];
                return _buildTutorialPage(step);
              },
            ),
          ),
          
          // Navigation controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                ElevatedButton.icon(
                  onPressed: _currentStep > 0 ? _previousStep : null,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Previous'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                ),
                
                // Step indicators (dots)
                Row(
                  children: List.generate(
                    _tutorialSteps.length,
                    (index) => GestureDetector(
                      onTap: () => _goToStep(index),
                      child: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentStep
                              ? Colors.brown[600]
                              : Colors.brown[200],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Next/Finish button
                ElevatedButton.icon(
                  onPressed: _currentStep < _tutorialSteps.length - 1 ? _nextStep : () {
                    Navigator.of(context).pop();
                  },
                  icon: Icon(
                    _currentStep < _tutorialSteps.length - 1 ? Icons.arrow_forward : Icons.check,
                    size: 18,
                  ),
                  label: Text(_currentStep < _tutorialSteps.length - 1 ? 'Next' : 'Finish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentStep < _tutorialSteps.length - 1 
                        ? Colors.brown[600] 
                        : Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialPage(TutorialStep step) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Icon
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.brown[200]!,
                  Colors.brown[100]!,
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: Text(
                step.icon,
                style: const TextStyle(fontSize: 48),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Title
          Text(
            step.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              step.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.brown,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Tips section
          if (step.tips != null && step.tips!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Tips:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...step.tips!.map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('• ', style: TextStyle(color: Colors.blue[600])),
                        Expanded(
                          child: Text(
                            tip,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class TutorialStep {
  final String title;
  final String description;
  final String icon;
  final String? imagePath;
  final List<String>? tips;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
    this.imagePath,
    this.tips,
  });
}