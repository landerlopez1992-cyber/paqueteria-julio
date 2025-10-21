import 'package:flutter/material.dart';
import '../main.dart';

class SuperAdminDashboardScreen extends StatefulWidget {
  const SuperAdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SuperAdminDashboardScreen> createState() => _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState extends State<SuperAdminDashboardScreen> {
  List<Map<String, dynamic>> _tenants = [];
  List<Map<String, dynamic>> _tenantsStats = [];
  bool _isLoading = true;
  String _filtro = 'TODOS'; // TODOS, ACTIVOS, INACTIVOS

  @override
  void initState() {
    super.initState();
    _cargarTenants();
  }

  Future<void> _cargarTenants() async {
    setState(() => _isLoading = true);
    try {
      // Cargar tenants
      final tenantsData = await supabase
          .from('tenants')
          .select('*')
          .order('fecha_creacion', ascending: false);

      // Cargar estadísticas
      final statsData = await supabase
          .from('tenant_stats')
          .select('*');

      setState(() {
        _tenants = List<Map<String, dynamic>>.from(tenantsData);
        _tenantsStats = List<Map<String, dynamic>>.from(statsData);
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar tenants: $e');
      setState(() => _isLoading = false);
      _mostrarMensaje('Error al cargar datos: $e');
    }
  }

  List<Map<String, dynamic>> get _tenantsFiltrados {
    if (_filtro == 'ACTIVOS') {
      return _tenants.where((t) => t['activo'] == true).toList();
    } else if (_filtro == 'INACTIVOS') {
      return _tenants.where((t) => t['activo'] == false).toList();
    }
    return _tenants;
  }

  Map<String, dynamic>? _getStats(String tenantId) {
    try {
      return _tenantsStats.firstWhere((s) => s['id'] == tenantId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF37474F),
        title: const Text('Panel Super Administrador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarTenants,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _cerrarSesion,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                _buildFiltros(),
                Expanded(child: _buildTenantsList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoCrearTenant,
        backgroundColor: const Color(0xFF4CAF50),
        icon: const Icon(Icons.add),
        label: const Text('Nueva Empresa'),
      ),
    );
  }

  Widget _buildHeader() {
    final totalTenants = _tenants.length;
    final activos = _tenants.where((t) => t['activo'] == true).length;
    final inactivos = totalTenants - activos;

    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFF5F5F5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatCard('Total Empresas', totalTenants.toString(), Colors.blue),
          _buildStatCard('Activas', activos.toString(), const Color(0xFF4CAF50)),
          _buildStatCard('Inactivas', inactivos.toString(), const Color(0xFFDC2626)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 150,
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF666666),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Filtrar: ', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Todos'),
            selected: _filtro == 'TODOS',
            onSelected: (selected) => setState(() => _filtro = 'TODOS'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Activos'),
            selected: _filtro == 'ACTIVOS',
            selectedColor: const Color(0xFF4CAF50).withOpacity(0.3),
            onSelected: (selected) => setState(() => _filtro = 'ACTIVOS'),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Inactivos'),
            selected: _filtro == 'INACTIVOS',
            selectedColor: const Color(0xFFDC2626).withOpacity(0.3),
            onSelected: (selected) => setState(() => _filtro = 'INACTIVOS'),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantsList() {
    if (_tenantsFiltrados.isEmpty) {
      return const Center(
        child: Text('No hay empresas registradas'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tenantsFiltrados.length,
      itemBuilder: (context, index) {
        final tenant = _tenantsFiltrados[index];
        final stats = _getStats(tenant['id']);
        return _buildTenantCard(tenant, stats);
      },
    );
  }

  Widget _buildTenantCard(Map<String, dynamic> tenant, Map<String, dynamic>? stats) {
    final activo = tenant['activo'] ?? false;
    final fechaCreacion = tenant['fecha_creacion'] != null
        ? _formatearFecha(DateTime.parse(tenant['fecha_creacion']))
        : 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: activo ? const Color(0xFF4CAF50) : const Color(0xFF999999),
          child: tenant['logo_url'] != null && tenant['logo_url'].toString().isNotEmpty
              ? ClipOval(child: Image.network(tenant['logo_url'], width: 40, height: 40, fit: BoxFit.cover))
              : Text(
                  tenant['nombre']?.toString().substring(0, 1).toUpperCase() ?? 'E',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
        title: Text(
          tenant['nombre'] ?? 'Sin nombre',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Slug: ${tenant['slug']}'),
            Text('Plan: ${tenant['plan']?.toString().toUpperCase()}'),
            Text('Creado: $fechaCreacion'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: activo ? const Color(0xFF4CAF50) : const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                activo ? 'ACTIVO' : 'INACTIVO',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, tenant),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'editar', child: Row(children: [Icon(Icons.edit), SizedBox(width: 8), Text('Editar')])),
                PopupMenuItem(
                  value: activo ? 'desactivar' : 'activar',
                  child: Row(children: [
                    Icon(activo ? Icons.block : Icons.check_circle),
                    const SizedBox(width: 8),
                    Text(activo ? 'Desactivar' : 'Activar'),
                  ]),
                ),
                const PopupMenuItem(value: 'cambiar_logo', child: Row(children: [Icon(Icons.image), SizedBox(width: 8), Text('Cambiar Logo')])),
                const PopupMenuItem(value: 'ver_detalles', child: Row(children: [Icon(Icons.info), SizedBox(width: 8), Text('Ver Detalles')])),
                const PopupMenuItem(value: 'eliminar', child: Row(children: [Icon(Icons.delete, color: Color(0xFFDC2626)), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: Color(0xFFDC2626)))])),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estadísticas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                if (stats != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('Usuarios', stats['total_usuarios']?.toString() ?? '0', Icons.people),
                      _buildMiniStat('Órdenes', stats['total_ordenes']?.toString() ?? '0', Icons.inventory),
                      _buildMiniStat('Activas', stats['ordenes_activas']?.toString() ?? '0', Icons.local_shipping),
                      _buildMiniStat('Entregadas', stats['ordenes_entregadas']?.toString() ?? '0', Icons.check_circle),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('Emisores', stats['total_emisores']?.toString() ?? '0', Icons.send),
                      _buildMiniStat('Destinatarios', stats['total_destinatarios']?.toString() ?? '0', Icons.location_on),
                    ],
                  ),
                ] else
                  const Text('No hay estadísticas disponibles'),
                const Divider(),
                Text('Email: ${tenant['email_contacto'] ?? 'No especificado'}'),
                Text('Teléfono: ${tenant['telefono'] ?? 'No especificado'}'),
                Text('Límite Órdenes: ${tenant['limite_ordenes'] ?? 'Ilimitado'}'),
                Text('Límite Usuarios: ${tenant['limite_usuarios'] ?? 'Ilimitado'}'),
                if (tenant['notas'] != null && tenant['notas'].toString().isNotEmpty)
                  Text('Notas: ${tenant['notas']}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF37474F)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
      ],
    );
  }

  void _handleMenuAction(String action, Map<String, dynamic> tenant) {
    switch (action) {
      case 'editar':
        _mostrarDialogoEditarTenant(tenant);
        break;
      case 'activar':
      case 'desactivar':
        _toggleActivarTenant(tenant);
        break;
      case 'cambiar_logo':
        _mostrarDialogoCambiarLogo(tenant);
        break;
      case 'ver_detalles':
        _mostrarDetallesTenant(tenant);
        break;
      case 'eliminar':
        _confirmarEliminarTenant(tenant);
        break;
    }
  }

  Future<void> _mostrarDialogoCrearTenant() async {
    final nombreCtrl = TextEditingController();
    final slugCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController();
    final logoUrlCtrl = TextEditingController();
    final notasCtrl = TextEditingController();
    String planSeleccionado = 'basico';

    // Auto-generar slug desde nombre
    nombreCtrl.addListener(() {
      final slug = nombreCtrl.text
          .toLowerCase()
          .replaceAll(' ', '-')
          .replaceAll(RegExp(r'[^a-z0-9-]'), '');
      slugCtrl.text = slug;
    });

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSB) => AlertDialog(
          title: const Text('Crear Nueva Empresa'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Empresa *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: slugCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Slug (URL única) *',
                      border: OutlineInputBorder(),
                      helperText: 'Ej: mi-empresa (solo letras, números y guiones)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email de Contacto',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: telefonoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: planSeleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Plan',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'basico', child: Text('Básico')),
                      DropdownMenuItem(value: 'premium', child: Text('Premium')),
                      DropdownMenuItem(value: 'enterprise', child: Text('Enterprise')),
                    ],
                    onChanged: (val) => setStateSB(() => planSeleccionado = val ?? 'basico'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: logoUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL del Logo (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notasCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Notas (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nombreCtrl.text.trim().isEmpty || slugCtrl.text.trim().isEmpty) {
                  _mostrarMensaje('Nombre y Slug son obligatorios');
                  return;
                }

                try {
                  await supabase.from('tenants').insert({
                    'nombre': nombreCtrl.text.trim(),
                    'slug': slugCtrl.text.trim(),
                    'email_contacto': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    'telefono': telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
                    'logo_url': logoUrlCtrl.text.trim().isEmpty ? null : logoUrlCtrl.text.trim(),
                    'plan': planSeleccionado,
                    'notas': notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim(),
                    'activo': true,
                  });

                  Navigator.of(ctx).pop();
                  _mostrarMensaje('Empresa creada exitosamente');
                  _cargarTenants();
                } catch (e) {
                  _mostrarMensaje('Error al crear empresa: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              child: const Text('Crear Empresa'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoEditarTenant(Map<String, dynamic> tenant) async {
    final nombreCtrl = TextEditingController(text: tenant['nombre']);
    final emailCtrl = TextEditingController(text: tenant['email_contacto'] ?? '');
    final telefonoCtrl = TextEditingController(text: tenant['telefono'] ?? '');
    final logoUrlCtrl = TextEditingController(text: tenant['logo_url'] ?? '');
    final notasCtrl = TextEditingController(text: tenant['notas'] ?? '');
    String planSeleccionado = tenant['plan'] ?? 'basico';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSB) => AlertDialog(
          title: Text('Editar: ${tenant['nombre']}'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: telefonoCtrl,
                    decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: planSeleccionado,
                    decoration: const InputDecoration(labelText: 'Plan', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'basico', child: Text('Básico')),
                      DropdownMenuItem(value: 'premium', child: Text('Premium')),
                      DropdownMenuItem(value: 'enterprise', child: Text('Enterprise')),
                    ],
                    onChanged: (val) => setStateSB(() => planSeleccionado = val ?? 'basico'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: logoUrlCtrl,
                    decoration: const InputDecoration(labelText: 'URL del Logo', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notasCtrl,
                    decoration: const InputDecoration(labelText: 'Notas', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await supabase.from('tenants').update({
                    'nombre': nombreCtrl.text.trim(),
                    'email_contacto': emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                    'telefono': telefonoCtrl.text.trim().isEmpty ? null : telefonoCtrl.text.trim(),
                    'logo_url': logoUrlCtrl.text.trim().isEmpty ? null : logoUrlCtrl.text.trim(),
                    'plan': planSeleccionado,
                    'notas': notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim(),
                  }).eq('id', tenant['id']);

                  Navigator.of(ctx).pop();
                  _mostrarMensaje('Empresa actualizada');
                  _cargarTenants();
                } catch (e) {
                  _mostrarMensaje('Error: $e');
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF9800)),
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActivarTenant(Map<String, dynamic> tenant) async {
    final nuevoEstado = !(tenant['activo'] ?? false);
    try {
      await supabase.from('tenants').update({'activo': nuevoEstado}).eq('id', tenant['id']);
      _mostrarMensaje('Empresa ${nuevoEstado ? 'activada' : 'desactivada'}');
      _cargarTenants();
    } catch (e) {
      _mostrarMensaje('Error: $e');
    }
  }

  Future<void> _mostrarDialogoCambiarLogo(Map<String, dynamic> tenant) async {
    final logoUrlCtrl = TextEditingController(text: tenant['logo_url'] ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cambiar Logo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: logoUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL del Logo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (logoUrlCtrl.text.isNotEmpty)
              Image.network(
                logoUrlCtrl.text,
                height: 100,
                errorBuilder: (context, error, stackTrace) => const Text('Error al cargar imagen'),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await supabase.from('tenants').update({
                  'logo_url': logoUrlCtrl.text.trim().isEmpty ? null : logoUrlCtrl.text.trim(),
                }).eq('id', tenant['id']);

                Navigator.of(ctx).pop();
                _mostrarMensaje('Logo actualizado');
                _cargarTenants();
              } catch (e) {
                _mostrarMensaje('Error: $e');
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _mostrarDetallesTenant(Map<String, dynamic> tenant) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tenant['nombre']),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${tenant['id']}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              const Divider(),
              Text('Slug: ${tenant['slug']}'),
              Text('Email: ${tenant['email_contacto'] ?? 'N/A'}'),
              Text('Teléfono: ${tenant['telefono'] ?? 'N/A'}'),
              Text('Plan: ${tenant['plan']}'),
              Text('Estado: ${tenant['activo'] ? 'ACTIVO' : 'INACTIVO'}'),
              Text('Límite Órdenes: ${tenant['limite_ordenes']}'),
              Text('Límite Usuarios: ${tenant['limite_usuarios']}'),
              const Divider(),
              Text('Creado: ${tenant['fecha_creacion']}'),
              if (tenant['notas'] != null) Text('Notas: ${tenant['notas']}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  Future<void> _confirmarEliminarTenant(Map<String, dynamic> tenant) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⚠️ Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de eliminar la empresa "${tenant['nombre']}"?\n\n'
          '⚠️ ADVERTENCIA: Esto eliminará TODOS los datos asociados:\n'
          '• Usuarios\n'
          '• Órdenes\n'
          '• Emisores y Destinatarios\n'
          '• Conversaciones de Chat\n\n'
          'Esta acción NO se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Eliminar Permanentemente'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await supabase.from('tenants').delete().eq('id', tenant['id']);
        _mostrarMensaje('Empresa eliminada');
        _cargarTenants();
      } catch (e) {
        _mostrarMensaje('Error al eliminar: $e');
      }
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Cierre de Sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  void _mostrarMensaje(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  String _formatearFecha(DateTime fecha) {
    final dia = fecha.day.toString().padLeft(2, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final anio = fecha.year.toString();
    return '$dia/$mes/$anio';
  }
}

