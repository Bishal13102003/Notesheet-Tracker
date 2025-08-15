// main.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://rdfxozbnvjxosriirwmv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJkZnhvemJudmp4b3NyaWlyd212Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI1ODQ1MTYsImV4cCI6MjA2ODE2MDUxNn0.-GwF8B-pCP6npTgU80svw8MpxMOhk1B3oyyv218iVPg',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //Widget -> themes, colours, text styles
      title: 'Notesheet Tracker',
      debugShowCheckedModeBanner: false, //DEBUG ribbon removal
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
      //ready made slots for common ui parts
      body: StreamBuilder<AuthState>(
        stream: Supabase
            .instance
            .client
            .auth
            .onAuthStateChange, //listen for authentication state change
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
  State<LoginPage> createState() => _LoginPageState(); //connects the widget to its mutable state object
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  } //cleans up animation controller to avoid memory leaks

  Future<void> signIn() async {
    setState(() => loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signup failed: $e')));
    }
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    backgroundBlendMode: BlendMode.overlay,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.note_alt_outlined,
                        size: 64,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Notesheet Tracker',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your notesheets with ease',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 30),
                      _buildInputField(
                        controller: emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline,
                        obscure: true,
                      ),
                      const SizedBox(height: 24),
                      if (loading)
                        const CircularProgressIndicator(color: Colors.white)
                      else
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            onPressed: signIn,
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: signUp,
                        child: const Text(
                          'Create an account',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
        prefixIcon: Icon(icon, color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.7),
            width: 1.5,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'Requester',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.reviews), label: 'Reviewer'),
          BottomNavigationBarItem(
            icon: Icon(Icons.admin_panel_settings),
            label: 'Admin',
          ),
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
  final assignedToNameController = TextEditingController();
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
        'assigned_to_name': assignedToNameController.text,
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submission failed: $e')));
    } finally {
      setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F6FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              shadowColor: Colors.black.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.note_add_rounded,
                          size: 32,
                          color: Colors.indigo,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Submit New Notesheet',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTextField(titleController, 'Title', Icons.title),
                    const SizedBox(height: 12),
                    _buildTextField(
                      descriptionController,
                      'Description',
                      Icons.description,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      deadlineController,
                      'Deadline (YYYY-MM-DD)',
                      Icons.calendar_today,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: urgency,
                      decoration: InputDecoration(
                        labelText: 'Urgency',
                        prefixIcon: const Icon(Icons.priority_high),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Low', child: Text('Low')),
                        DropdownMenuItem(
                          value: 'Normal',
                          child: Text('Normal'),
                        ),
                        DropdownMenuItem(value: 'High', child: Text('High')),
                      ],
                      onChanged: (value) => setState(() => urgency = value!),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: selectAndUploadPDF,
                      icon: const Icon(Icons.attach_file),
                      label: Text(pdfName ?? 'Select PDF'),
                    ),
                    Padding(
                      /*  */
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextField(
                        controller: assignedToNameController,
                        decoration: InputDecoration(
                          labelText: "Assigned To",
                          labelStyle: TextStyle(fontWeight: FontWeight.w500),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 14,
                            horizontal: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    /*  */
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: uploading ? null : submitNotesheet,
                      child: uploading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Submit Notesheet',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// class ReviewerDashboard extends StatefulWidget {
//   const ReviewerDashboard({super.key});

//   @override
//   State<ReviewerDashboard> createState() => _ReviewerDashboardState();
// }

// class _ReviewerDashboardState extends State<ReviewerDashboard> {
//   final List<Map<String, dynamic>> dummyNotesheets = [
//     {
//       'title': 'Budget Approval Q3',
//       'status': 'Pending',
//       'deadline': '2025-07-20',
//     },
//     {
//       'title': 'Project Proposal X',
//       'status': 'In Review',
//       'deadline': '2025-07-18',
//     },
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Pending Notesheets',
//             style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 16),
//           Expanded(
//             child: ListView.builder(
//               itemCount: dummyNotesheets.length,
//               itemBuilder: (context, index) {
//                 final item = dummyNotesheets[index];
//                 return Card(
//                   elevation: 3,
//                   margin: const EdgeInsets.symmetric(vertical: 8),
//                   child: ListTile(
//                     leading: const Icon(
//                       Icons.picture_as_pdf,
//                       color: Colors.red,
//                     ),
//                     title: Text(
//                       item['title'],
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     subtitle: Text('Deadline: ${item['deadline']}'),
//                     trailing: Chip(
//                       label: Text(item['status']),
//                       backgroundColor: item['status'] == 'Pending'
//                           ? Colors.orange.shade100
//                           : Colors.blue.shade100,
//                     ),
//                     onTap: () {
//                       // TODO: Add review
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class ReviewerDashboard extends StatefulWidget {
  const ReviewerDashboard({super.key});

  @override
  State<ReviewerDashboard> createState() => _ReviewerDashboardState();
}

class _ReviewerDashboardState extends State<ReviewerDashboard> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> notesheets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotesheets();
  }

  Future<void> fetchNotesheets() async {
    try {
      final response = await supabase
          .from('notesheets')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        notesheets = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching notesheets: $e');
      setState(() => isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade100;
      case 'Approved':
        return Colors.green.shade100;
      case 'Rejected':
        return Colors.red.shade100;
      default:
        return Colors.blue.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pending Notesheets',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : notesheets.isEmpty
                ? const Center(
                    child: Text(
                      'No notesheets available.',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: notesheets.length,
                    itemBuilder: (context, index) {
                      final item = notesheets[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: const Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                            size: 32,
                          ),
                          title: Text(
                            item['title'] ?? 'Untitled',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (item['assigned_to_name'] != null &&
                                  item['assigned_to_name']
                                      .toString()
                                      .isNotEmpty)
                                Text(
                                  'Assigned to: ${item['assigned_to_name']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              if (item['urgency'] != null)
                                Text(
                                  'Urgency: ${item['urgency']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              if (item['deadline'] != null)
                                Text(
                                  'Deadline: ${DateTime.parse(item['deadline']).toLocal().toString().split(' ')[0]}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                            ],
                          ),
                          trailing: Chip(
                            label: Text(item['status'] ?? 'Unknown'),
                            backgroundColor: _statusColor(item['status'] ?? ''),
                          ),
                          onTap: () {
                            // TODO: Open notesheet details/review screen
                            final pdfUrl = item['pdf_url'];
                            if (pdfUrl != null &&
                                pdfUrl.toString().isNotEmpty) {
                              // Open the PDF in the browser
                              launchUrl(
                                Uri.parse(pdfUrl),
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'No PDF available for this notesheet',
                                  ),
                                ),
                              );
                            }
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
          const Text(
            'System Overview',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
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
          const Text(
            'Activity Logs',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
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
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: Colors.indigo),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
