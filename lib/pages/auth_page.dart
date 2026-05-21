import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:tvplus/integrations/supabase_service.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

@NowaGenerated()
class AuthPage extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() {
    return _AuthPageState();
  }
}

@NowaGenerated()
class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _useCode = false;

  final FocusNode _emailNode = FocusNode();
  final FocusNode _passwordNode = FocusNode();
  final FocusNode _nombreNode = FocusNode();
  final FocusNode _codeNode = FocusNode();
  final FocusNode _submitNode = FocusNode();
  final FocusNode _toggleCodeNode = FocusNode();
  final FocusNode _toggleModeNode = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _codeController.dispose();
    _emailNode.dispose();
    _passwordNode.dispose();
    _nombreNode.dispose();
    _codeNode.dispose();
    _submitNode.dispose();
    _toggleCodeNode.dispose();
    _toggleModeNode.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (_isLoading) {
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (_useCode) {
        final bool isValid = await SupabaseService().signInWithCode(
          _codeController.text,
        );
        if (isValid) {
          if (mounted) {
            context.go('/');
          }
          return;
        } else {
          throw Exception('Código de acceso no válido o expirado');
        }
      }
      if (_isLogin) {
        await SupabaseService().signIn(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        await SupabaseService().signUpWithProfile(
          _emailController.text,
          _passwordController.text,
          _nombreController.text,
        );
      }
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Error: ${e.toString()}';
        if (e.toString().contains('429')) {
          errorMsg = 'Demasiados intentos. Intenta más tarde o usa un código.';
        } else if (e.toString().contains('Exception:')) {
          errorMsg = e.toString().replaceFirst('Exception: ', '');
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.black,
                    Colors.red.withValues(alpha: 0.05),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 40.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 100.0,
                      width: 100.0,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(24.0),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Icon(
                        Icons.tv_rounded,
                        size: 60.0,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 40.0),
                    Text(
                      _useCode
                          ? 'Acceso rápido'
                          : (_isLogin ? 'TvPlus' : 'Crea tu cuenta'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _useCode ? 'Ingresa tu código' : 'aritoLp',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 14.0,
                        letterSpacing: 1.2,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 48.0),
                    if (_useCode)
                      _buildTextField(
                        _codeController,
                        'Código de acceso',
                        Icons.vpn_key_outlined,
                        focusNode: _codeNode,
                        nextNode: _submitNode,
                      )
                    else ...[
                      if (!_isLogin) ...[
                        _buildTextField(
                          _nombreController,
                          'Nombre completo',
                          Icons.person_outline,
                          focusNode: _nombreNode,
                          nextNode: _emailNode,
                        ),
                        const SizedBox(height: 16.0),
                      ],
                      _buildTextField(
                        _emailController,
                        'Email',
                        Icons.email_outlined,
                        focusNode: _emailNode,
                        nextNode: _passwordNode,
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextField(
                        _passwordController,
                        'Contraseña',
                        Icons.lock_outline,
                        isPassword: true,
                        focusNode: _passwordNode,
                        nextNode: _submitNode,
                      ),
                    ],
                    const SizedBox(height: 32.0),
                    Focus(
                      focusNode: _submitNode,
                      onFocusChange: (hasFocus) {
                        if (hasFocus) {
                          Scrollable.ensureVisible(
                            context,
                            alignment: 0.5,
                            duration: const Duration(milliseconds: 300),
                          );
                        }
                        setState(() {});
                      },
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.enter ||
                                event.logicalKey == LogicalKeyboardKey.select ||
                                event.logicalKey == LogicalKeyboardKey.accept)) {
                          _handleAuth();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        height: 56.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16.0),
                          boxShadow: [
                            if (_submitNode.hasFocus)
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.3),
                                blurRadius: 15.0,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: TextButton(
                          onPressed: _handleAuth,
                          style: TextButton.styleFrom(
                            backgroundColor: _submitNode.hasFocus
                                ? Colors.red
                                : Colors.white.withValues(alpha: 0.05),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            side: BorderSide(
                              color: _submitNode.hasFocus
                                  ? Colors.white
                                  : Colors.white10,
                              width: 2.0,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24.0,
                                  width: 24.0,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _useCode
                                      ? 'Validar código'
                                      : (_isLogin ? 'Ingresar' : 'Registrar'),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.0,
                                    fontWeight: _submitNode.hasFocus
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    Focus(
                      focusNode: _toggleCodeNode,
                      onFocusChange: (hasFocus) {
                        if (hasFocus) {
                          Scrollable.ensureVisible(
                            context,
                            alignment: 0.5,
                            duration: const Duration(milliseconds: 300),
                          );
                        }
                        setState(() {});
                      },
                      onKeyEvent: (node, event) {
                        if (event is KeyDownEvent &&
                            (event.logicalKey == LogicalKeyboardKey.enter ||
                                event.logicalKey == LogicalKeyboardKey.select ||
                                event.logicalKey ==
                                    LogicalKeyboardKey.accept)) {
                          setState(() => _useCode = !_useCode);
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: TextButton(
                        onPressed: () => setState(() => _useCode = !_useCode),
                        style: TextButton.styleFrom(
                          side: BorderSide(
                            color: _toggleCodeNode.hasFocus
                                ? Colors.white
                                : Colors.transparent,
                            width: 2.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          _useCode
                              ? 'Volver a Email/Password'
                              : '¿Tienes un código de acceso?',
                          style: TextStyle(
                            color: _toggleCodeNode.hasFocus
                                ? Colors.white
                                : Colors.white54,
                            fontWeight: _toggleCodeNode.hasFocus
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    if (!_useCode)
                      Focus(
                        focusNode: _toggleModeNode,
                        onFocusChange: (hasFocus) {
                          if (hasFocus) {
                            Scrollable.ensureVisible(
                              context,
                              alignment: 0.5,
                              duration: const Duration(milliseconds: 300),
                            );
                          }
                          setState(() {});
                        },
                        onKeyEvent: (node, event) {
                          if (event is KeyDownEvent &&
                              (event.logicalKey == LogicalKeyboardKey.enter ||
                                  event.logicalKey == LogicalKeyboardKey.select ||
                                  event.logicalKey ==
                                      LogicalKeyboardKey.accept)) {
                            setState(() => _isLogin = !_isLogin);
                            return KeyEventResult.handled;
                          }
                          return KeyEventResult.ignored;
                        },
                        child: TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          style: TextButton.styleFrom(
                            side: BorderSide(
                              color: _toggleModeNode.hasFocus
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          child: Text(
                            _isLogin
                                ? '¿No tienes cuenta? Regístrate'
                                : '¿Ya tienes cuenta? Inicia sesión',
                            style: TextStyle(
                              color: _toggleModeNode.hasFocus
                                  ? Colors.white
                                  : Colors.white38,
                              fontSize: 12.0,
                              fontWeight: _toggleModeNode.hasFocus
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    FocusNode? focusNode,
    FocusNode? nextNode,
  }) {
    final bool hasFocus = focusNode?.hasFocus ?? false;
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.select): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
        LogicalKeySet(LogicalKeyboardKey.accept): const ActivateIntent(),
      },
      child: Container(
        decoration: BoxDecoration(
          color: hasFocus
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: hasFocus ? Colors.white : Colors.white10,
            width: hasFocus ? 3.0 : 1.0,
          ),
        ),
        child: TextField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          autofocus: false,
          focusNode: focusNode,
          onEditingComplete: () {
            if (nextNode != null) {
              nextNode.requestFocus();
            } else {
              _handleAuth();
            }
          },
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: hasFocus ? Colors.white : Colors.white38,
              fontWeight: hasFocus ? FontWeight.bold : FontWeight.normal,
            ),
            prefixIcon: Icon(
              icon,
              color: hasFocus ? Colors.white : Colors.white38,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
          ),
          onSubmitted: (value) {
            if (nextNode != null) {
              nextNode.requestFocus();
            } else {
              _handleAuth();
            }
          },
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _emailNode.addListener(() => setState(() {}));
    _passwordNode.addListener(() => setState(() {}));
    _nombreNode.addListener(() => setState(() {}));
    _codeNode.addListener(() => setState(() {}));
    _submitNode.addListener(() => setState(() {}));
    _toggleCodeNode.addListener(() => setState(() {}));
    _toggleModeNode.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_useCode) {
        _codeNode.requestFocus();
      } else if (!_isLogin) {
        _nombreNode.requestFocus();
      } else {
        _emailNode.requestFocus();
      }
    });
  }
} // Cierre definitivo de la clase _AuthPageState
