import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey =
    String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
    runApp(const ConfigErrorApp());
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
  runApp(const NexoraApp());
}

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        home: Scaffold(
          backgroundColor: Color(0xFF0B1020),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'NEXORA belum dikonfigurasi. Tambahkan SUPABASE_URL dan '
                'SUPABASE_PUBLISHABLE_KEY pada GitHub Actions Secrets.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ),
      );
}

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEXORA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1020),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C7CFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF171F35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (supabase.auth.currentSession != null) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  final displayName = TextEditingController();
  bool registering = false;
  bool busy = false;
  String? message;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    displayName.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final e = email.text.trim();
      final p = password.text;
      if (e.isEmpty || p.length < 6) {
        throw Exception('Masukkan email dan kata sandi minimal 6 karakter.');
      }
      if (registering) {
        if (displayName.text.trim().isEmpty) {
          throw Exception('Nama tampilan harus diisi.');
        }
        final result = await supabase.auth.signUp(
          email: e,
          password: p,
          data: {'display_name': displayName.text.trim()},
        );
        if (result.session == null) {
          message = 'Akun dibuat. Periksa email untuk konfirmasi, lalu masuk.';
        }
      } else {
        await supabase.auth.signInWithPassword(email: e, password: p);
      }
    } on AuthException catch (e) {
      message = e.message;
    } catch (e) {
      message = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 34),
                  const Icon(Icons.forum_rounded,
                      size: 58, color: Color(0xFF8794FF)),
                  const SizedBox(height: 18),
                  const Text('NEXORA',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 34,
                          letterSpacing: 5,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  const Text('Connect beyond distance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white60)),
                  const SizedBox(height: 42),
                  Text(registering ? 'Buat akun' : 'Selamat datang kembali',
                      style: const TextStyle(
                          fontSize: 23, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  if (registering) ...[
                    TextField(
                      controller: displayName,
                      decoration:
                          const InputDecoration(labelText: 'Nama tampilan'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: password,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Kata sandi'),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 14),
                    Text(message!,
                        style: const TextStyle(color: Color(0xFFFFB4AB))),
                  ],
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(registering ? 'DAFTAR' : 'MASUK'),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                              registering = !registering;
                              message = null;
                            }),
                    child: Text(registering
                        ? 'Sudah punya akun? Masuk'
                        : 'Belum punya akun? Daftar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final search = TextEditingController();
  List<Map<String, dynamic>> users = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<void> loadUsers() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final rows = await supabase
          .from('profiles')
          .select('id, display_name, username')
          .neq('id', supabase.auth.currentUser!.id)
          .order('display_name');
      users = List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> startChat(Map<String, dynamic> user) async {
    try {
      final created = await supabase
          .from('conversations')
          .insert({
            'created_by': supabase.auth.currentUser!.id,
            'is_group': false,
          })
          .select('id')
          .single();

      final conversationId = created['id'] as String;
      await supabase.from('conversation_members').insert([
        {
          'conversation_id': conversationId,
          'user_id': supabase.auth.currentUser!.id,
        },
        {
          'conversation_id': conversationId,
          'user_id': user['id'],
        },
      ]);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            otherUser: user,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak bisa memulai chat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = search.text.toLowerCase();
    final visible = users.where((u) {
      final name = (u['display_name'] ?? u['username'] ?? '').toString();
      return name.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXORA',
            style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: () => supabase.auth.signOut(),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Cari pengguna...',
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('MULAI PERCAKAPAN',
                  style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      letterSpacing: 1.6,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('Gagal memuat pengguna:\n$error',
                              textAlign: TextAlign.center),
                        ),
                      )
                    : visible.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada pengguna lain.\nDaftarkan akun kedua untuk mencoba chat.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white60),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: loadUsers,
                            child: ListView.separated(
                              itemCount: visible.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, indent: 76, endIndent: 18),
                              itemBuilder: (context, index) {
                                final user = visible[index];
                                final name = (user['display_name'] ??
                                        user['username'] ??
                                        'Pengguna')
                                    .toString();
                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 5),
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        const Color(0xFF27345B),
                                    child: Text(name.isEmpty
                                        ? '?'
                                        : name[0].toUpperCase()),
                                  ),
                                  title: Text(name),
                                  subtitle: Text(
                                      user['username'] == null
                                          ? 'Pengguna NEXORA'
                                          : '@${user['username']}',
                                      style: const TextStyle(
                                          color: Colors.white54)),
                                  trailing:
                                      const Icon(Icons.chat_bubble_outline),
                                  onTap: () => startChat(user),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic> otherUser;

  const ChatScreen({
    super.key,
    required this.conversationId,
    required this.otherUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final message = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> messageStream;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    messageStream = supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', widget.conversationId)
        .order('created_at');
  }

  @override
  void dispose() {
    message.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final text = message.text.trim();
    if (text.isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await supabase.from('messages').insert({
        'conversation_id': widget.conversationId,
        'sender_id': supabase.auth.currentUser!.id,
        'body': text,
      });
      message.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Pesan gagal dikirim: $e')));
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherName = (widget.otherUser['display_name'] ??
            widget.otherUser['username'] ??
            'Pengguna')
        .toString();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFF27345B),
              child: Text(otherName.isEmpty ? '?' : otherName[0].toUpperCase()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(otherName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17)),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: messageStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Gagal memuat pesan: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snapshot.data!;
                if (rows.isEmpty) {
                  return const Center(
                    child: Text('Mulai percakapan.',
                        style: TextStyle(color: Colors.white54)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final mine =
                        row['sender_id'] == supabase.auth.currentUser!.id;
                    return Align(
                      alignment:
                          mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 300),
                        margin: const EdgeInsets.only(bottom: 9),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 11),
                        decoration: BoxDecoration(
                          color: mine
                              ? const Color(0xFF5264D8)
                              : const Color(0xFF1B2540),
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Text((row['body'] ?? '').toString()),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: message,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Tulis pesan...',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 17, vertical: 13),
                      ),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: sending ? null : send,
                    icon: sending
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
