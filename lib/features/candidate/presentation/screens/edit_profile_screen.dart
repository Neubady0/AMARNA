import 'package:amarnamovil/data/local/database_helper.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _studiesController;
  late final TextEditingController _experienceController;

  @override
  void initState() {
    super.initState();
    // Inicializamos los controladores con los datos actuales del usuario
    _nameController = TextEditingController(text: widget.user['name'] ?? '');
    _studiesController = TextEditingController(text: widget.user['studies'] ?? '');
    _experienceController = TextEditingController(text: widget.user['experience'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studiesController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final dbHelper = DatabaseHelper();
      final data = {
        'name': _nameController.text,
        'studies': _studiesController.text,
        'experience': _experienceController.text,
      };

      await dbHelper.updateUserProfile(widget.user['id'], data);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado con éxito.'),
          backgroundColor: Colors.green,
        ),
      );

      // Opcional: Devolver los datos actualizados a la pantalla anterior
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _studiesController,
                decoration: const InputDecoration(
                  labelText: 'Estudios',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.school_outlined),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Experiencia Laboral',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_outline),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save_alt_outlined),
                label: const Text('Guardar Cambios'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
