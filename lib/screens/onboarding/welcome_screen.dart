import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  final Function onComplete;

  const WelcomeScreen({Key? key, required this.onComplete}) : super(key: key);

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black12, // Example color for kprimecolor
      body: Column(children: [
        SizedBox(
          height: 200,
        ),
        Image.asset('assets/images/ChatZone Logo Design.png'),
        Center(
            child: Text(
          'Welcome to chatzone  ',
          style: TextStyle(color: Colors.white, fontSize: 28), // Example color for kTextColor
        )),
        SizedBox(
          height: 20,
        ),
        Text("Connect, chat, in a zone where conversations flow.",
            style: TextStyle(color: Colors.white, fontSize: 16)), // Example color for kTextColor
        SizedBox(
          height: 200,
        ),
        ElevatedButton(
            onPressed: () {
              widget.onComplete();
            },
            child: Text('Get Started'))
      ]),
    );
  }
}