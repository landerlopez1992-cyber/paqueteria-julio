// Datos de municipios de Cuba organizados por provincia
class MunicipiosCuba {
  static const Map<String, List<String>> municipiosPorProvincia = {
    'Pinar del Río': [
      'Pinar del Río',
      'Consolación del Sur',
      'Mantua',
      'Minas de Matahambre',
      'Viñales',
      'La Palma',
      'Los Palacios',
      'Sandino',
      'Guane',
      'San Juan y Martínez',
      'San Luis'
    ],
    'Artemisa': [
      'Artemisa',
      'Bahía Honda',
      'Candelaria',
      'Guanajay',
      'Güira de Melena',
      'Mariel',
      'San Antonio de los Baños',
      'Bauta',
      'Caimito',
      'Alquízar',
      'Güines',
      'Melena del Sur',
      'Nueva Paz',
      'Quivicán',
      'San José de las Lajas',
      'Bejucal',
      'Madruga',
      'Palma Soriano'
    ],
    'La Habana': [
      'Playa',
      'Plaza de la Revolución',
      'Centro Habana',
      'La Habana Vieja',
      'Regla',
      'La Habana del Este',
      'Guanabacoa',
      'San Miguel del Padrón',
      'Diez de Octubre',
      'Cerro',
      'Marianao',
      'La Lisa',
      'Boyeros',
      'Arroyo Naranjo',
      'Cotorro'
    ],
    'Mayabeque': [
      'Batabanó',
      'Bejucal',
      'Güines',
      'Jaruco',
      'Madruga',
      'Melena del Sur',
      'Nueva Paz',
      'Quivicán',
      'San José de las Lajas',
      'Santa Cruz del Norte',
      'San Nicolás'
    ],
    'Matanzas': [
      'Matanzas',
      'Cárdenas',
      'Colón',
      'Jagüey Grande',
      'Jovellanos',
      'Pedro Betancourt',
      'Perico',
      'Unión de Reyes',
      'Calimete',
      'Ciénaga de Zapata',
      'Limonar',
      'Los Arabos',
      'Martí',
      'Varadero'
    ],
    'Cienfuegos': [
      'Cienfuegos',
      'Aguada de Pasajeros',
      'Cruces',
      'Cumanayagua',
      'Lajas',
      'Palmira',
      'Rodas',
      'Santa Isabel de las Lajas'
    ],
    'Villa Clara': [
      'Santa Clara',
      'Caibarién',
      'Camajuaní',
      'Cifuentes',
      'Corralillo',
      'Encrucijada',
      'Manicaragua',
      'Placetas',
      'Quemado de Güines',
      'Ranchuelo',
      'Remedios',
      'Sagua la Grande',
      'Santo Domingo'
    ],
    'Sancti Spíritus': [
      'Sancti Spíritus',
      'Cabaiguán',
      'Fomento',
      'Jatibonico',
      'La Sierpe',
      'Taguasco',
      'Trinidad',
      'Yaguajay'
    ],
    'Ciego de Ávila': [
      'Ciego de Ávila',
      'Baraguá',
      'Bolivia',
      'Chambas',
      'Ciro Redondo',
      'Florencia',
      'Majagua',
      'Morón',
      'Primero de Enero',
      'Venezuela'
    ],
    'Camagüey': [
      'Camagüey',
      'Carlos M. de Céspedes',
      'Esmeralda',
      'Florida',
      'Guáimaro',
      'Jimaguayú',
      'Minas',
      'Najasa',
      'Nuevitas',
      'Santa Cruz del Sur',
      'Sibanicú',
      'Sierra de Cubitas',
      'Vertientes'
    ],
    'Las Tunas': [
      'Las Tunas',
      'Amancio',
      'Colombia',
      'Jesús Menéndez',
      'Jobabo',
      'Majibacoa',
      'Manatí',
      'Puerto Padre'
    ],
    'Granma': [
      'Bayamo',
      'Bartolomé Masó',
      'Buey Arriba',
      'Campechuela',
      'Cauto Cristo',
      'Guisa',
      'Jiguaní',
      'Manzanillo',
      'Media Luna',
      'Niquero',
      'Pilón',
      'Río Cauto',
      'Yara'
    ],
    'Holguín': [
      'Holguín',
      'Antilla',
      'Báguanos',
      'Banes',
      'Cacocum',
      'Calixto García',
      'Cueto',
      'Frank País',
      'Gibara',
      'Mayarí',
      'Moa',
      'Rafael Freyre',
      'Sagua de Tánamo',
      'Urbano Noris'
    ],
    'Santiago de Cuba': [
      'Santiago de Cuba',
      'Contramaestre',
      'Guamá',
      'Julio Antonio Mella',
      'Palma Soriano',
      'San Luis',
      'Segundo Frente',
      'Songo-La Maya',
      'Tercer Frente'
    ],
    'Guantánamo': [
      'Guantánamo',
      'Baracoa',
      'Caimanera',
      'El Salvador',
      'Imías',
      'Maisí',
      'Manuel Tames',
      'Niceto Pérez',
      'San Antonio del Sur',
      'Yateras'
    ],
    'Isla de la Juventud': [
      'Nueva Gerona',
      'La Demajagua'
    ]
  };

  static List<String> getProvincias() {
    return municipiosPorProvincia.keys.toList();
  }

  static List<String> getMunicipiosPorProvincia(String provincia) {
    return municipiosPorProvincia[provincia] ?? [];
  }
}


