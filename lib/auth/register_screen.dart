import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  int? selectedGender = 1; // 1 for Male
  bool _isLoginSelected = false;
  bool _isPasswordVisible = false;
  double radius = 20;

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height:22),
                Icon(Icons.wifi, color: Colors.blue, size: 40),
                Text(
                  "Get Started now",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Create an account or log in to explore about our app",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(color: Colors.grey, fontSize: 14),
                ),
                SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 44, vertical: 12),
                          decoration: BoxDecoration(
                            color: _isLoginSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            "Log In",
                            style: GoogleFonts.roboto(
                              color: _isLoginSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isLoginSelected = false),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 50, vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isLoginSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Text(
                            "Sign Up",
                            style: GoogleFonts.roboto(
                              color: !_isLoginSelected ? Colors.black : Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                // Name Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 4),
                      child: Text(
                        "Name",
                        style: GoogleFonts.roboto(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(radius)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(radius)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue),borderRadius: BorderRadius.circular(radius)),
                        errorText: authState.getFieldError('name'),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter your name' : null,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Username Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 4),
                      child: Text(
                        "Username",
                        style: GoogleFonts.roboto(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    TextFormField(
                      controller: usernameController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(radius)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(radius)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue),borderRadius: BorderRadius.circular(radius)),
                        errorText: authState.getFieldError('username'),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Please enter a username' : null,
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Email Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 4),
                      child: Text(
                        "Email",
                        style: GoogleFonts.roboto(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(radius)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(radius)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue),borderRadius: BorderRadius.circular(radius)),
                        errorText: authState.getFieldError('email'),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your email';
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        return !emailRegex.hasMatch(value) ? 'Please enter a valid email address' : null;
                      },
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Password Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 4),
                      child: Text(
                        "Password",
                        style: GoogleFonts.roboto(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(radius)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(radius)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue),borderRadius: BorderRadius.circular(radius)),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        errorText: authState.getFieldError('password'),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter a password';
                        if (value.length < 8) return 'Password must be at least 8 characters long';
                        final hasUppercase = value.contains(RegExp(r'[A-Z]'));
                        final hasLowercase = value.contains(RegExp(r'[a-z]'));
                        final hasNumber = value.contains(RegExp(r'[0-9]'));
                        final hasSpecialChar = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
                        return !hasUppercase || !hasLowercase || !hasNumber || !hasSpecialChar
                            ? 'Password must include uppercase, lowercase, number, and special character'
                            : null;
                      },
                    ),
                  ],
                ),
                SizedBox(height: 12),
                // Gender Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 10, bottom: 4),
                      child: Text(
                        "Gender",
                        style: GoogleFonts.roboto(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                    DropdownButtonFormField<int>(
                      value: selectedGender,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(radius)),
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey),borderRadius: BorderRadius.circular(radius)),
                        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.blue),borderRadius: BorderRadius.circular(radius)),
                        errorText: authState.getFieldError('gender'),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                      ),
                      items: [
                        DropdownMenuItem(value: 1, child: Text('Male', style: TextStyle(color: Colors.black))),
                        DropdownMenuItem(value: 2, child: Text('Female', style: TextStyle(color: Colors.black))),
                        DropdownMenuItem(value: 3, child: Text('Others', style: TextStyle(color: Colors.black))),
                      ],
                      onChanged: (value) => setState(() => selectedGender = value),
                      validator: (value) => value == null ? 'Please select a gender' : null,
                      dropdownColor: Colors.white,
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: authState.isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      bool success = await ref.read(authProvider.notifier).register(
                        nameController.text,
                        usernameController.text,
                        emailController.text,
                        passwordController.text,
                        selectedGender!,
                      );
                      if (success) {

                        Future.delayed(Duration(seconds: 1), () => context.go('/login'));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: authState.isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Sign Up', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}