// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://rdfxozbnvjxosriirwmv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkZnhvemJudmp4b3NyaWlyd212Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1ODQ1MTYsImV4cCI6MjA2ODE2MDUxNn0.-GwF8B-pCP6npTgU80svw8MpxMOhk1B3oyyv218iVPg',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notesheet Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF4F6F8),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
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
    return Scaffold(
      body: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = Supabase.instance.client.auth.currentSession;
          if (session != null) {
            return const Dashboard();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  Future<void> signIn() async {
    setState(() => loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    }
    setState(() => loading = false);
  }

  Future<void> signUp() async {
    setState(() => loading = true);
    try {
      await Supabase.instance.client.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your email to verify.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $e')),
      );
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Notesheet Tracker', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (loading) const CircularProgressIndicator(),
              if (!loading) ...[
                ElevatedButton(onPressed: signIn, child: const Text('Login')),
                TextButton(onPressed: signUp, child: const Text('Signup')),
              ]
            ],
          ),
        ),
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const RequesterDashboard(),
    const ReviewerDashboard(),
    const AdminDashboard(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notesheet Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.request_page), label: 'Requester'),
          BottomNavigationBarItem(icon: Icon(Icons.reviews), label: 'Reviewer'),
          BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
        ],
      ),
    );
  }
}

class RequesterDashboard extends StatefulWidget {
  const RequesterDashboard({super.key});

  @override
  State<RequesterDashboard> createState() => _RequesterDashboardState();
}

class _RequesterDashboardState extends State<RequesterDashboard> {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final deadlineController = TextEditingController();
  String urgency = 'Normal';
  String? pdfName;
  Uint8List? pdfBytes;
  bool uploading = false;

  Future<void> selectAndUploadPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        pdfName = result.files.single.name;
        pdfBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> submitNotesheet() async {
    if (pdfName == null || pdfBytes == null) return;
    setState(() => uploading = true);

    final userId = Supabase.instance.client.auth.currentUser!.id;
    final fileRef = 'notesheets/$userId/$pdfName';

    try {
      final storage = Supabase.instance.client.storage;
      await storage.from('notesheets').uploadBinary(fileRef, pdfBytes!);
      final pdfUrl = storage.from('notesheets').getPublicUrl(fileRef);

      await Supabase.instance.client.from('notesheets').insert({
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'pdf_url': pdfUrl,
        'deadline': deadlineController.text.trim(),
        'urgency': urgency,
        'status': 'Pending',
        'created_by': userId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notesheet submitted successfully')),
      );

      titleController.clear();
      descriptionController.clear();
      deadlineController.clear();
      pdfName = null;
      pdfBytes = null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission failed: $e')),
      );
    } finally {
      setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '📄 Submit New Notesheet',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: deadlineController,
                    decoration: const InputDecoration(labelText: 'Deadline (YYYY-MM-DD)'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: urgency,
                    items: const [
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                      DropdownMenuItem(value: 'Normal', child: Text('Normal')),
                      DropdownMenuItem(value: 'High', child: Text('High')),
                    ],
                    onChanged: (value) => setState(() => urgency = value!),
                    decoration: const InputDecoration(labelText: 'Urgency'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: selectAndUploadPDF,
                    icon: const Icon(Icons.attach_file),
                    label: Text(pdfName ?? 'Select PDF'),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: uploading ? null : submitNotesheet,
                    child: uploading
                        ? const CircularProgressIndicator()
                        : const Text('Submit Notesheet'),
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

class ReviewerDashboard extends StatefulWidget {
  const ReviewerDashboard({super.key});

  @override
  State<ReviewerDashboard> createState() => _ReviewerDashboardState();
}

class _ReviewerDashboardState extends State<ReviewerDashboard> {
  final List<Map<String, dynamic>> dummyNotesheets = [
    {
      'title': 'Budget Approval Q3',
      'status': 'Pending',
      'deadline': '2025-07-20',
    },
    {
      'title': 'Project Proposal X',
      'status': 'In Review',
      'deadline': '2025-07-18',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pending Notesheets', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: dummyNotesheets.length,
              itemBuilder: (context, index) {
                final item = dummyNotesheets[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                    title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Deadline: ${item['deadline']}'),
                    trailing: Chip(
                      label: Text(item['status']),
                      backgroundColor: item['status'] == 'Pending'
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                    ),
                    onTap: () {
                      // TODO: Add review
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard('Total Users', '57', Icons.group),
              _buildStatCard('Departments', '6', Icons.account_tree),
              _buildStatCard('Notesheets Today', '12', Icons.description),
            ],
          ),
          const SizedBox(height: 32),
          const Text('Activity Logs', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: const [
                ListTile(
                  leading: Icon(Icons.login, color: Colors.indigo),
                  title: Text('User john.doe@example.com logged in'),
                  subtitle: Text('10 mins ago'),
                ),
                ListTile(
                  leading: Icon(Icons.edit_note, color: Colors.indigo),
                  title: Text('New notesheet submitted by user123'),
                  subtitle: Text('30 mins ago'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.shade200, blurRadius: 8, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: Colors.indigo),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

