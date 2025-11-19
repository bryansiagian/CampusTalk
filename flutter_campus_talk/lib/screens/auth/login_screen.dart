import 'package:flutter/material.dart';
import '../../services/api_services.dart';
import '../main_navigation_screen.dart'; // <--- PASTIKAN INI DIIMPOR
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'register_screen.dart'; // Import RegisterScreen

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiServices _apiService = ApiServices();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email dan password tidak boleh kosong')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      if(user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selamat datang, ${user.name}!')),
        );
        Navigator.of(context).pushReplacement(
          // PERBAIKAN: Ganti HomeScreen() dengan MainNavigationScreen()
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception:', ''))),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context)  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login CampusTalk', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Pastikan Anda memiliki 'assets/logo.png' atau hapus baris ini
              // Image.asset('assets/logo.png', height: 100,),
              // const SizedBox(height: 32,),
              Text(
                'Selamat Datang di Campus Talk',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Kampus',
                  hintText: 'contoh@del.ac.id',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius:  BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              _isLoading
                ? SpinKitWave(color: Theme.of(context).primaryColor, size: 30.0)
                  : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Login', style: TextStyle(fontSize: 18)),
                    ),
                  ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  // PERBAIKAN: Ganti pushNamed dengan MaterialPageRoute untuk konsistensi
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text('Belum punya akun? Daftar sekarang', style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        ),
      ),
    );
  }
}