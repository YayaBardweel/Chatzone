import 'package:flutter/material.dart';

import '../../widgets/PrimeColors.dart';

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
      backgroundColor: kprimecolor,
      body: Column(children: [
        SizedBox(
          height: 200,
        ),
        Image.asset('assets/images/ChatZone Logo Design.png'),
        Center(
            child: Text(
          'Welcome to chatzone  ',
          style: TextStyle(color: kTextColor, fontSize: 28),
        )),
        SizedBox(
          height: 20,
        ),
        Text("Connect, chat, in a zone where conversations flow.",
            style: TextStyle(color: kTextColor, fontSize: 16)),
        SizedBox(
          height: 200,
        ),
        ElevatedButton(
            onPressed: () {

              widget.onComplete();
            },
            child: Text('Get Started')
        )
      ]),
    );
  }
}
