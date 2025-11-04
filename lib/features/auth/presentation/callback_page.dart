import 'package:flutter/material.dart';

/// A placeholder page for the web callback route.
/// Not used in the mobile flow since AppAuth handles redirects natively.
class CallbackPage extends StatelessWidget {
  const CallbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Callback (not used in mobile flow)'),
      ),
    );
  }
}
