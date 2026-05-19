const List<String> artworkTypes = [
  'Painting',
  'Drawing',
  'Print',
  'Photography',
  'Sculpture',
  'Textile',
  'Digital',
  'Other',
];

const List<String> artworkConditions = [
  'Excellent',
  'Good',
  'Fair',
  'Poor',
];

const List<String> artworkMediums = [
  'Oil on canvas',
  'Acrylic',
  'Watercolor',
  'Gouache',
  'Pencil',
  'Charcoal',
  'Ink',
  'Pastel',
  'Mixed media',
  'Digital',
  'Etching',
  'Lithograph',
  'Screen print',
  'Bronze',
  'Marble',
  'Ceramic',
  'Fabric',
  'Other',
];

enum SortBy { dateAdded, title, artist, year }

const kDefaultRemotePath = 'ArtworksManager';
