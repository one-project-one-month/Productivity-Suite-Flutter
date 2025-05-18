import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({super.key});

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  @override
  Widget build(BuildContext context) {
    TextTheme textTheme = TextTheme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Pomodoro Timer'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(16.0)),
                  /*gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment(1, 0.9),
                    colors: [Color(0xff6C63FF), Color(0xff63B3ED)],
                  ),*/
                ),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Focus Better \nAchieve More',
                          style: textTheme.headlineMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0045f3),
                          ),
                        ),
                        SizedBox(height: 20.0),
                        Text(
                          'Your all-in-one productivity suite that helps you manage time, tasks, notes, and finances effectively',
                          style: textTheme.titleMedium!.copyWith(
                            color: const Color(0xff0045f3),
                          ),
                        ),
                        SizedBox(height: 24.0),
                        SizedBox(
                          width: double.infinity,
                          height: 52.0,
                          child: FilledButton.tonal(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xff0045f3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12.0),
                                ),
                              ),
                            ),
                            onPressed: () {
                              context.goNamed('to_do');
                            },
                            child: Text(
                              'Get Started Free',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.0),
                        SizedBox(
                          width: double.infinity,
                          height: 52.0,
                          child: TextButton(
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                side: BorderSide(
                                  color: const Color(0xff0045f3),
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12.0),
                                ),
                              ),
                            ),
                            onPressed: () {},
                            child: Text(
                              'Login Here',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff0045f3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              Text(
                'All tools in one place',
                style: textTheme.titleLarge!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.0),
              Row(
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: () {
                        context.go('/pomodoro');
                      },
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.access_time,
                                color: const Color(0xff0045f3),
                                size: 35.0,
                              ),
                              SizedBox(height: 12.0),
                              Text(
                                'Pomodoro Timer',
                                style: textTheme.titleMedium,
                              ),
                              SizedBox(height: 8.0),
                              Text('Focus better with time blocks'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.checklist,
                              color: const Color(0xff0045f3),
                              size: 35.0,
                            ),
                            SizedBox(height: 12.0),
                            Text('To-Do List', style: textTheme.titleMedium),
                            SizedBox(height: 8.0),
                            Text('Organize tasks by priority'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Flexible(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.note_add,
                              color: const Color(0xff0045f3),
                              size: 35.0,
                            ),
                            SizedBox(height: 12.0),
                            Text('Notes', style: textTheme.titleMedium),
                            SizedBox(height: 8.0),
                            Text('Capture important information'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: const Color(0xff0045f3),
                              size: 35.0,
                            ),
                            SizedBox(height: 12.0),
                            Text(
                              'Budget Tracker',
                              style: textTheme.titleMedium,
                            ),
                            SizedBox(height: 8.0),
                            Text('Monitor income and expenses'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 40.0),
              Align(
                child: Text(
                  style: textTheme.titleMedium,
                  'Ready to boost your productivity?',
                ),
              ),
              SizedBox(height: 12.0),
              Align(
                child: Text(
                  textAlign: TextAlign.center,
                  'Join thousands of users who have transformed their workflow with FlowFocus.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
