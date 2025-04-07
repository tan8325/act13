import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

final auth = FirebaseAuth.instance;

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Auth Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      home: AuthSwitcher(),
    );
  }
}

class AuthSwitcher extends StatefulWidget {
  @override
  _AuthSwitcherState createState() => _AuthSwitcherState();
}

class _AuthSwitcherState extends State<AuthSwitcher> {
  bool showLogin = true;

  void toggle() => setState(() => showLogin = !showLogin);

  @override
  Widget build(BuildContext context) {
    return AuthForm(isLogin: showLogin, onToggle: toggle);
  }
}

class AuthForm extends StatefulWidget {
  final bool isLogin;
  final VoidCallback onToggle;

  AuthForm({required this.isLogin, required this.onToggle});

  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  String error = '';
  Color errorColor = Colors.red;
  bool loading = false;

  void _submit() async {
    setState(() {
      error = '';
      loading = true;
    });

    try {
      if (widget.isLogin) {
        await auth.signInWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passCtrl.text,
        );

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => ProfileScreen()),
          );
        }
      } else {
        await auth.createUserWithEmailAndPassword(
          email: emailCtrl.text.trim(),
          password: passCtrl.text,
        );

        emailCtrl.clear();
        passCtrl.clear();

        if (mounted) {
          setState(() {
            error = 'Account created successfully. Please sign in.';
            errorColor = Colors.green;
          });
          widget.onToggle();
        }
      }
    } catch (e) {
      setState(() {
        error = e.toString().split('] ').last;
        errorColor = Colors.red;
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isLogin ? 'Sign In' : 'Register';
    final toggleText =
        widget.isLogin ? 'No account? Register' : 'Have an account? Sign In';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(labelText: 'Email'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
              ),
              ElevatedButton(
                onPressed: loading ? null : _submit,
                child: Text(title),
              ),
              TextButton(onPressed: widget.onToggle, child: Text(toggleText)),
              if (error.isNotEmpty)
                Text(
                  error,
                  style: TextStyle(color: errorColor),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  final newPassCtrl = TextEditingController();

  void _changePassword(BuildContext context) async {
    final newPass = newPassCtrl.text;
    if (newPass.length < 6) {
      _showMsg(context, 'Password must be at least 6 characters');
      return;
    }

    try {
      await auth.currentUser?.updatePassword(newPass);
      _showMsg(context, 'Password changed successfully');
      newPassCtrl.clear();
    } catch (_) {
      _showMsg(context, 'Error changing password. Reauthenticate and try again.');
    }
  }

  void _logout(BuildContext context) async {
    await auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AuthSwitcher()),
    );
  }

  void _showMsg(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: () => _logout(context)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome,', style: TextStyle(fontSize: 18)),
            Text(
              user?.email ?? '',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              decoration: InputDecoration(labelText: 'New Password'),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _changePassword(context),
                child: Text('Change Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
