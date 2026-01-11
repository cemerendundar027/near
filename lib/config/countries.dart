/// Kapsamlı ülke listesi
/// 240+ ülke, bayrak, alan kodu
class Country {
  final String code; // ISO 3166-1 alpha-2 code (TR, US, GB...)
  final String dial; // Dial code (+90, +1, +44...)
  final String name; // Country name in Turkish
  final String nameEn; // Country name in English
  final String flag; // Flag emoji

  const Country({
    required this.code,
    required this.dial,
    required this.name,
    required this.nameEn,
    required this.flag,
  });

  /// Format: +90 (Türkiye)
  String get displayName => '$dial ($name)';

  /// Format: 🇹🇷 +90 Türkiye
  String get fullDisplay => '$flag $dial $name';
}

/// Tüm ülkeler listesi - alfabetik sıralı (Türkçe)
const List<Country> allCountries = [
  // Önce Türkiye (varsayılan)
  Country(
    code: 'TR',
    dial: '+90',
    name: 'Türkiye',
    nameEn: 'Turkey',
    flag: '🇹🇷',
  ),

  // A
  Country(
    code: 'AF',
    dial: '+93',
    name: 'Afganistan',
    nameEn: 'Afghanistan',
    flag: '🇦🇫',
  ),
  Country(
    code: 'AX',
    dial: '+358',
    name: 'Åland Adaları',
    nameEn: 'Åland Islands',
    flag: '🇦🇽',
  ),
  Country(
    code: 'DE',
    dial: '+49',
    name: 'Almanya',
    nameEn: 'Germany',
    flag: '🇩🇪',
  ),
  Country(
    code: 'US',
    dial: '+1',
    name: 'Amerika Birleşik Devletleri',
    nameEn: 'United States',
    flag: '🇺🇸',
  ),
  Country(
    code: 'AS',
    dial: '+1684',
    name: 'Amerikan Samoası',
    nameEn: 'American Samoa',
    flag: '🇦🇸',
  ),
  Country(
    code: 'AD',
    dial: '+376',
    name: 'Andorra',
    nameEn: 'Andorra',
    flag: '🇦🇩',
  ),
  Country(
    code: 'AO',
    dial: '+244',
    name: 'Angola',
    nameEn: 'Angola',
    flag: '🇦🇴',
  ),
  Country(
    code: 'AI',
    dial: '+1264',
    name: 'Anguilla',
    nameEn: 'Anguilla',
    flag: '🇦🇮',
  ),
  Country(
    code: 'AQ',
    dial: '+672',
    name: 'Antarktika',
    nameEn: 'Antarctica',
    flag: '🇦🇶',
  ),
  Country(
    code: 'AG',
    dial: '+1268',
    name: 'Antigua ve Barbuda',
    nameEn: 'Antigua and Barbuda',
    flag: '🇦🇬',
  ),
  Country(
    code: 'AR',
    dial: '+54',
    name: 'Arjantin',
    nameEn: 'Argentina',
    flag: '🇦🇷',
  ),
  Country(
    code: 'AL',
    dial: '+355',
    name: 'Arnavutluk',
    nameEn: 'Albania',
    flag: '🇦🇱',
  ),
  Country(
    code: 'AW',
    dial: '+297',
    name: 'Aruba',
    nameEn: 'Aruba',
    flag: '🇦🇼',
  ),
  Country(
    code: 'AU',
    dial: '+61',
    name: 'Avustralya',
    nameEn: 'Australia',
    flag: '🇦🇺',
  ),
  Country(
    code: 'AT',
    dial: '+43',
    name: 'Avusturya',
    nameEn: 'Austria',
    flag: '🇦🇹',
  ),
  Country(
    code: 'AZ',
    dial: '+994',
    name: 'Azerbaycan',
    nameEn: 'Azerbaijan',
    flag: '🇦🇿',
  ),

  // B
  Country(
    code: 'BS',
    dial: '+1242',
    name: 'Bahamalar',
    nameEn: 'Bahamas',
    flag: '🇧🇸',
  ),
  Country(
    code: 'BH',
    dial: '+973',
    name: 'Bahreyn',
    nameEn: 'Bahrain',
    flag: '🇧🇭',
  ),
  Country(
    code: 'BD',
    dial: '+880',
    name: 'Bangladeş',
    nameEn: 'Bangladesh',
    flag: '🇧🇩',
  ),
  Country(
    code: 'BB',
    dial: '+1246',
    name: 'Barbados',
    nameEn: 'Barbados',
    flag: '🇧🇧',
  ),
  Country(
    code: 'BY',
    dial: '+375',
    name: 'Belarus',
    nameEn: 'Belarus',
    flag: '🇧🇾',
  ),
  Country(
    code: 'BE',
    dial: '+32',
    name: 'Belçika',
    nameEn: 'Belgium',
    flag: '🇧🇪',
  ),
  Country(
    code: 'BZ',
    dial: '+501',
    name: 'Belize',
    nameEn: 'Belize',
    flag: '🇧🇿',
  ),
  Country(
    code: 'BJ',
    dial: '+229',
    name: 'Benin',
    nameEn: 'Benin',
    flag: '🇧🇯',
  ),
  Country(
    code: 'BM',
    dial: '+1441',
    name: 'Bermuda',
    nameEn: 'Bermuda',
    flag: '🇧🇲',
  ),
  Country(
    code: 'AE',
    dial: '+971',
    name: 'Birleşik Arap Emirlikleri',
    nameEn: 'United Arab Emirates',
    flag: '🇦🇪',
  ),
  Country(
    code: 'GB',
    dial: '+44',
    name: 'Birleşik Krallık',
    nameEn: 'United Kingdom',
    flag: '🇬🇧',
  ),
  Country(
    code: 'BO',
    dial: '+591',
    name: 'Bolivya',
    nameEn: 'Bolivia',
    flag: '🇧🇴',
  ),
  Country(
    code: 'BA',
    dial: '+387',
    name: 'Bosna Hersek',
    nameEn: 'Bosnia and Herzegovina',
    flag: '🇧🇦',
  ),
  Country(
    code: 'BW',
    dial: '+267',
    name: 'Botsvana',
    nameEn: 'Botswana',
    flag: '🇧🇼',
  ),
  Country(
    code: 'BR',
    dial: '+55',
    name: 'Brezilya',
    nameEn: 'Brazil',
    flag: '🇧🇷',
  ),
  Country(
    code: 'BN',
    dial: '+673',
    name: 'Brunei',
    nameEn: 'Brunei',
    flag: '🇧🇳',
  ),
  Country(
    code: 'BG',
    dial: '+359',
    name: 'Bulgaristan',
    nameEn: 'Bulgaria',
    flag: '🇧🇬',
  ),
  Country(
    code: 'BF',
    dial: '+226',
    name: 'Burkina Faso',
    nameEn: 'Burkina Faso',
    flag: '🇧🇫',
  ),
  Country(
    code: 'BI',
    dial: '+257',
    name: 'Burundi',
    nameEn: 'Burundi',
    flag: '🇧🇮',
  ),
  Country(
    code: 'BT',
    dial: '+975',
    name: 'Butan',
    nameEn: 'Bhutan',
    flag: '🇧🇹',
  ),

  // C
  Country(
    code: 'CV',
    dial: '+238',
    name: 'Cabo Verde',
    nameEn: 'Cape Verde',
    flag: '🇨🇻',
  ),
  Country(
    code: 'KY',
    dial: '+1345',
    name: 'Cayman Adaları',
    nameEn: 'Cayman Islands',
    flag: '🇰🇾',
  ),
  Country(
    code: 'GI',
    dial: '+350',
    name: 'Cebelitarık',
    nameEn: 'Gibraltar',
    flag: '🇬🇮',
  ),
  Country(
    code: 'DZ',
    dial: '+213',
    name: 'Cezayir',
    nameEn: 'Algeria',
    flag: '🇩🇿',
  ),
  Country(
    code: 'DJ',
    dial: '+253',
    name: 'Cibuti',
    nameEn: 'Djibouti',
    flag: '🇩🇯',
  ),
  Country(code: 'TD', dial: '+235', name: 'Çad', nameEn: 'Chad', flag: '🇹🇩'),
  Country(
    code: 'CZ',
    dial: '+420',
    name: 'Çekya',
    nameEn: 'Czech Republic',
    flag: '🇨🇿',
  ),
  Country(code: 'CN', dial: '+86', name: 'Çin', nameEn: 'China', flag: '🇨🇳'),

  // D
  Country(
    code: 'DK',
    dial: '+45',
    name: 'Danimarka',
    nameEn: 'Denmark',
    flag: '🇩🇰',
  ),
  Country(
    code: 'DM',
    dial: '+1767',
    name: 'Dominika',
    nameEn: 'Dominica',
    flag: '🇩🇲',
  ),
  Country(
    code: 'DO',
    dial: '+1809',
    name: 'Dominik Cumhuriyeti',
    nameEn: 'Dominican Republic',
    flag: '🇩🇴',
  ),

  // E
  Country(
    code: 'EC',
    dial: '+593',
    name: 'Ekvador',
    nameEn: 'Ecuador',
    flag: '🇪🇨',
  ),
  Country(
    code: 'GQ',
    dial: '+240',
    name: 'Ekvator Ginesi',
    nameEn: 'Equatorial Guinea',
    flag: '🇬🇶',
  ),
  Country(
    code: 'SV',
    dial: '+503',
    name: 'El Salvador',
    nameEn: 'El Salvador',
    flag: '🇸🇻',
  ),
  Country(
    code: 'ID',
    dial: '+62',
    name: 'Endonezya',
    nameEn: 'Indonesia',
    flag: '🇮🇩',
  ),
  Country(
    code: 'ER',
    dial: '+291',
    name: 'Eritre',
    nameEn: 'Eritrea',
    flag: '🇪🇷',
  ),
  Country(
    code: 'AM',
    dial: '+374',
    name: 'Ermenistan',
    nameEn: 'Armenia',
    flag: '🇦🇲',
  ),
  Country(
    code: 'EE',
    dial: '+372',
    name: 'Estonya',
    nameEn: 'Estonia',
    flag: '🇪🇪',
  ),
  Country(
    code: 'SZ',
    dial: '+268',
    name: 'Esvati̇ni̇',
    nameEn: 'Eswatini',
    flag: '🇸🇿',
  ),
  Country(
    code: 'ET',
    dial: '+251',
    name: 'Etiyopya',
    nameEn: 'Ethiopia',
    flag: '🇪🇹',
  ),

  // F
  Country(
    code: 'FK',
    dial: '+500',
    name: 'Falkland Adaları',
    nameEn: 'Falkland Islands',
    flag: '🇫🇰',
  ),
  Country(
    code: 'FO',
    dial: '+298',
    name: 'Faroe Adaları',
    nameEn: 'Faroe Islands',
    flag: '🇫🇴',
  ),
  Country(
    code: 'MA',
    dial: '+212',
    name: 'Fas',
    nameEn: 'Morocco',
    flag: '🇲🇦',
  ),
  Country(code: 'FJ', dial: '+679', name: 'Fiji', nameEn: 'Fiji', flag: '🇫🇯'),
  Country(
    code: 'CI',
    dial: '+225',
    name: 'Fildişi Sahili',
    nameEn: "Côte d'Ivoire",
    flag: '🇨🇮',
  ),
  Country(
    code: 'PH',
    dial: '+63',
    name: 'Filipinler',
    nameEn: 'Philippines',
    flag: '🇵🇭',
  ),
  Country(
    code: 'FI',
    dial: '+358',
    name: 'Finlandiya',
    nameEn: 'Finland',
    flag: '🇫🇮',
  ),
  Country(
    code: 'FR',
    dial: '+33',
    name: 'Fransa',
    nameEn: 'France',
    flag: '🇫🇷',
  ),
  Country(
    code: 'GF',
    dial: '+594',
    name: 'Fransız Guyanası',
    nameEn: 'French Guiana',
    flag: '🇬🇫',
  ),
  Country(
    code: 'PF',
    dial: '+689',
    name: 'Fransız Polinezyası',
    nameEn: 'French Polynesia',
    flag: '🇵🇫',
  ),

  // G
  Country(
    code: 'GA',
    dial: '+241',
    name: 'Gabon',
    nameEn: 'Gabon',
    flag: '🇬🇦',
  ),
  Country(
    code: 'GM',
    dial: '+220',
    name: 'Gambiya',
    nameEn: 'Gambia',
    flag: '🇬🇲',
  ),
  Country(
    code: 'GH',
    dial: '+233',
    name: 'Gana',
    nameEn: 'Ghana',
    flag: '🇬🇭',
  ),
  Country(
    code: 'GN',
    dial: '+224',
    name: 'Gine',
    nameEn: 'Guinea',
    flag: '🇬🇳',
  ),
  Country(
    code: 'GW',
    dial: '+245',
    name: 'Gine-Bissau',
    nameEn: 'Guinea-Bissau',
    flag: '🇬🇼',
  ),
  Country(
    code: 'GD',
    dial: '+1473',
    name: 'Grenada',
    nameEn: 'Grenada',
    flag: '🇬🇩',
  ),
  Country(
    code: 'GL',
    dial: '+299',
    name: 'Grönland',
    nameEn: 'Greenland',
    flag: '🇬🇱',
  ),
  Country(
    code: 'GP',
    dial: '+590',
    name: 'Guadeloupe',
    nameEn: 'Guadeloupe',
    flag: '🇬🇵',
  ),
  Country(
    code: 'GU',
    dial: '+1671',
    name: 'Guam',
    nameEn: 'Guam',
    flag: '🇬🇺',
  ),
  Country(
    code: 'GT',
    dial: '+502',
    name: 'Guatemala',
    nameEn: 'Guatemala',
    flag: '🇬🇹',
  ),
  Country(
    code: 'GG',
    dial: '+44',
    name: 'Guernsey',
    nameEn: 'Guernsey',
    flag: '🇬🇬',
  ),
  Country(
    code: 'ZA',
    dial: '+27',
    name: 'Güney Afrika',
    nameEn: 'South Africa',
    flag: '🇿🇦',
  ),
  Country(
    code: 'KR',
    dial: '+82',
    name: 'Güney Kore',
    nameEn: 'South Korea',
    flag: '🇰🇷',
  ),
  Country(
    code: 'SS',
    dial: '+211',
    name: 'Güney Sudan',
    nameEn: 'South Sudan',
    flag: '🇸🇸',
  ),
  Country(
    code: 'GE',
    dial: '+995',
    name: 'Gürcistan',
    nameEn: 'Georgia',
    flag: '🇬🇪',
  ),
  Country(
    code: 'GY',
    dial: '+592',
    name: 'Guyana',
    nameEn: 'Guyana',
    flag: '🇬🇾',
  ),

  // H
  Country(
    code: 'HT',
    dial: '+509',
    name: 'Haiti',
    nameEn: 'Haiti',
    flag: '🇭🇹',
  ),
  Country(
    code: 'IN',
    dial: '+91',
    name: 'Hindistan',
    nameEn: 'India',
    flag: '🇮🇳',
  ),
  Country(
    code: 'HR',
    dial: '+385',
    name: 'Hırvatistan',
    nameEn: 'Croatia',
    flag: '🇭🇷',
  ),
  Country(
    code: 'NL',
    dial: '+31',
    name: 'Hollanda',
    nameEn: 'Netherlands',
    flag: '🇳🇱',
  ),
  Country(
    code: 'HN',
    dial: '+504',
    name: 'Honduras',
    nameEn: 'Honduras',
    flag: '🇭🇳',
  ),
  Country(
    code: 'HK',
    dial: '+852',
    name: 'Hong Kong',
    nameEn: 'Hong Kong',
    flag: '🇭🇰',
  ),

  // I
  Country(code: 'IQ', dial: '+964', name: 'Irak', nameEn: 'Iraq', flag: '🇮🇶'),
  Country(
    code: 'VG',
    dial: '+1284',
    name: 'İngiliz Virgin Adaları',
    nameEn: 'British Virgin Islands',
    flag: '🇻🇬',
  ),
  Country(code: 'IR', dial: '+98', name: 'İran', nameEn: 'Iran', flag: '🇮🇷'),
  Country(
    code: 'IE',
    dial: '+353',
    name: 'İrlanda',
    nameEn: 'Ireland',
    flag: '🇮🇪',
  ),
  Country(
    code: 'ES',
    dial: '+34',
    name: 'İspanya',
    nameEn: 'Spain',
    flag: '🇪🇸',
  ),
  Country(
    code: 'IL',
    dial: '+972',
    name: 'İsrail',
    nameEn: 'Israel',
    flag: '🇮🇱',
  ),
  Country(
    code: 'SE',
    dial: '+46',
    name: 'İsveç',
    nameEn: 'Sweden',
    flag: '🇸🇪',
  ),
  Country(
    code: 'CH',
    dial: '+41',
    name: 'İsviçre',
    nameEn: 'Switzerland',
    flag: '🇨🇭',
  ),
  Country(
    code: 'IT',
    dial: '+39',
    name: 'İtalya',
    nameEn: 'Italy',
    flag: '🇮🇹',
  ),
  Country(
    code: 'IS',
    dial: '+354',
    name: 'İzlanda',
    nameEn: 'Iceland',
    flag: '🇮🇸',
  ),

  // J
  Country(
    code: 'JM',
    dial: '+1876',
    name: 'Jamaika',
    nameEn: 'Jamaica',
    flag: '🇯🇲',
  ),
  Country(
    code: 'JP',
    dial: '+81',
    name: 'Japonya',
    nameEn: 'Japan',
    flag: '🇯🇵',
  ),
  Country(
    code: 'JE',
    dial: '+44',
    name: 'Jersey',
    nameEn: 'Jersey',
    flag: '🇯🇪',
  ),
  Country(
    code: 'JO',
    dial: '+962',
    name: 'Ürdün',
    nameEn: 'Jordan',
    flag: '🇯🇴',
  ),

  // K
  Country(
    code: 'KH',
    dial: '+855',
    name: 'Kamboçya',
    nameEn: 'Cambodia',
    flag: '🇰🇭',
  ),
  Country(
    code: 'CM',
    dial: '+237',
    name: 'Kamerun',
    nameEn: 'Cameroon',
    flag: '🇨🇲',
  ),
  Country(
    code: 'CA',
    dial: '+1',
    name: 'Kanada',
    nameEn: 'Canada',
    flag: '🇨🇦',
  ),
  Country(
    code: 'ME',
    dial: '+382',
    name: 'Karadağ',
    nameEn: 'Montenegro',
    flag: '🇲🇪',
  ),
  Country(
    code: 'QA',
    dial: '+974',
    name: 'Katar',
    nameEn: 'Qatar',
    flag: '🇶🇦',
  ),
  Country(
    code: 'KZ',
    dial: '+7',
    name: 'Kazakistan',
    nameEn: 'Kazakhstan',
    flag: '🇰🇿',
  ),
  Country(
    code: 'KE',
    dial: '+254',
    name: 'Kenya',
    nameEn: 'Kenya',
    flag: '🇰🇪',
  ),
  Country(
    code: 'CY',
    dial: '+357',
    name: 'Kıbrıs',
    nameEn: 'Cyprus',
    flag: '🇨🇾',
  ),
  Country(
    code: 'KG',
    dial: '+996',
    name: 'Kırgızistan',
    nameEn: 'Kyrgyzstan',
    flag: '🇰🇬',
  ),
  Country(
    code: 'KI',
    dial: '+686',
    name: 'Kiribati',
    nameEn: 'Kiribati',
    flag: '🇰🇮',
  ),
  Country(
    code: 'CO',
    dial: '+57',
    name: 'Kolombiya',
    nameEn: 'Colombia',
    flag: '🇨🇴',
  ),
  Country(
    code: 'KM',
    dial: '+269',
    name: 'Komorlar',
    nameEn: 'Comoros',
    flag: '🇰🇲',
  ),
  Country(
    code: 'CG',
    dial: '+242',
    name: 'Kongo',
    nameEn: 'Congo',
    flag: '🇨🇬',
  ),
  Country(
    code: 'CD',
    dial: '+243',
    name: 'Kongo Demokratik Cumhuriyeti',
    nameEn: 'Democratic Republic of the Congo',
    flag: '🇨🇩',
  ),
  Country(
    code: 'XK',
    dial: '+383',
    name: 'Kosova',
    nameEn: 'Kosovo',
    flag: '🇽🇰',
  ),
  Country(
    code: 'CR',
    dial: '+506',
    name: 'Kosta Rika',
    nameEn: 'Costa Rica',
    flag: '🇨🇷',
  ),
  Country(
    code: 'KW',
    dial: '+965',
    name: 'Kuveyt',
    nameEn: 'Kuwait',
    flag: '🇰🇼',
  ),
  Country(code: 'CU', dial: '+53', name: 'Küba', nameEn: 'Cuba', flag: '🇨🇺'),
  Country(
    code: 'KP',
    dial: '+850',
    name: 'Kuzey Kore',
    nameEn: 'North Korea',
    flag: '🇰🇵',
  ),
  Country(
    code: 'MK',
    dial: '+389',
    name: 'Kuzey Makedonya',
    nameEn: 'North Macedonia',
    flag: '🇲🇰',
  ),

  // L
  Country(code: 'LA', dial: '+856', name: 'Laos', nameEn: 'Laos', flag: '🇱🇦'),
  Country(
    code: 'LS',
    dial: '+266',
    name: 'Lesoto',
    nameEn: 'Lesotho',
    flag: '🇱🇸',
  ),
  Country(
    code: 'LV',
    dial: '+371',
    name: 'Letonya',
    nameEn: 'Latvia',
    flag: '🇱🇻',
  ),
  Country(
    code: 'LR',
    dial: '+231',
    name: 'Liberya',
    nameEn: 'Liberia',
    flag: '🇱🇷',
  ),
  Country(
    code: 'LY',
    dial: '+218',
    name: 'Libya',
    nameEn: 'Libya',
    flag: '🇱🇾',
  ),
  Country(
    code: 'LI',
    dial: '+423',
    name: 'Lihtenştayn',
    nameEn: 'Liechtenstein',
    flag: '🇱🇮',
  ),
  Country(
    code: 'LT',
    dial: '+370',
    name: 'Litvanya',
    nameEn: 'Lithuania',
    flag: '🇱🇹',
  ),
  Country(
    code: 'LB',
    dial: '+961',
    name: 'Lübnan',
    nameEn: 'Lebanon',
    flag: '🇱🇧',
  ),
  Country(
    code: 'LU',
    dial: '+352',
    name: 'Lüksemburg',
    nameEn: 'Luxembourg',
    flag: '🇱🇺',
  ),

  // M
  Country(
    code: 'HU',
    dial: '+36',
    name: 'Macaristan',
    nameEn: 'Hungary',
    flag: '🇭🇺',
  ),
  Country(
    code: 'MG',
    dial: '+261',
    name: 'Madagaskar',
    nameEn: 'Madagascar',
    flag: '🇲🇬',
  ),
  Country(
    code: 'MO',
    dial: '+853',
    name: 'Makao',
    nameEn: 'Macau',
    flag: '🇲🇴',
  ),
  Country(
    code: 'MW',
    dial: '+265',
    name: 'Malavi',
    nameEn: 'Malawi',
    flag: '🇲🇼',
  ),
  Country(
    code: 'MV',
    dial: '+960',
    name: 'Maldivler',
    nameEn: 'Maldives',
    flag: '🇲🇻',
  ),
  Country(
    code: 'MY',
    dial: '+60',
    name: 'Malezya',
    nameEn: 'Malaysia',
    flag: '🇲🇾',
  ),
  Country(code: 'ML', dial: '+223', name: 'Mali', nameEn: 'Mali', flag: '🇲🇱'),
  Country(
    code: 'MT',
    dial: '+356',
    name: 'Malta',
    nameEn: 'Malta',
    flag: '🇲🇹',
  ),
  Country(
    code: 'IM',
    dial: '+44',
    name: 'Man Adası',
    nameEn: 'Isle of Man',
    flag: '🇮🇲',
  ),
  Country(
    code: 'MH',
    dial: '+692',
    name: 'Marshall Adaları',
    nameEn: 'Marshall Islands',
    flag: '🇲🇭',
  ),
  Country(
    code: 'MQ',
    dial: '+596',
    name: 'Martinik',
    nameEn: 'Martinique',
    flag: '🇲🇶',
  ),
  Country(
    code: 'MU',
    dial: '+230',
    name: 'Mauritius',
    nameEn: 'Mauritius',
    flag: '🇲🇺',
  ),
  Country(
    code: 'YT',
    dial: '+262',
    name: 'Mayotte',
    nameEn: 'Mayotte',
    flag: '🇾🇹',
  ),
  Country(
    code: 'MX',
    dial: '+52',
    name: 'Meksika',
    nameEn: 'Mexico',
    flag: '🇲🇽',
  ),
  Country(
    code: 'FM',
    dial: '+691',
    name: 'Mikronezya',
    nameEn: 'Micronesia',
    flag: '🇫🇲',
  ),
  Country(
    code: 'EG',
    dial: '+20',
    name: 'Mısır',
    nameEn: 'Egypt',
    flag: '🇪🇬',
  ),
  Country(
    code: 'MN',
    dial: '+976',
    name: 'Moğolistan',
    nameEn: 'Mongolia',
    flag: '🇲🇳',
  ),
  Country(
    code: 'MD',
    dial: '+373',
    name: 'Moldova',
    nameEn: 'Moldova',
    flag: '🇲🇩',
  ),
  Country(
    code: 'MC',
    dial: '+377',
    name: 'Monako',
    nameEn: 'Monaco',
    flag: '🇲🇨',
  ),
  Country(
    code: 'MS',
    dial: '+1664',
    name: 'Montserrat',
    nameEn: 'Montserrat',
    flag: '🇲🇸',
  ),
  Country(
    code: 'MR',
    dial: '+222',
    name: 'Moritanya',
    nameEn: 'Mauritania',
    flag: '🇲🇷',
  ),
  Country(
    code: 'MZ',
    dial: '+258',
    name: 'Mozambik',
    nameEn: 'Mozambique',
    flag: '🇲🇿',
  ),
  Country(
    code: 'MM',
    dial: '+95',
    name: 'Myanmar',
    nameEn: 'Myanmar',
    flag: '🇲🇲',
  ),

  // N
  Country(
    code: 'NA',
    dial: '+264',
    name: 'Namibya',
    nameEn: 'Namibia',
    flag: '🇳🇦',
  ),
  Country(
    code: 'NR',
    dial: '+674',
    name: 'Nauru',
    nameEn: 'Nauru',
    flag: '🇳🇷',
  ),
  Country(
    code: 'NP',
    dial: '+977',
    name: 'Nepal',
    nameEn: 'Nepal',
    flag: '🇳🇵',
  ),
  Country(
    code: 'NE',
    dial: '+227',
    name: 'Nijer',
    nameEn: 'Niger',
    flag: '🇳🇪',
  ),
  Country(
    code: 'NG',
    dial: '+234',
    name: 'Nijerya',
    nameEn: 'Nigeria',
    flag: '🇳🇬',
  ),
  Country(
    code: 'NI',
    dial: '+505',
    name: 'Nikaragua',
    nameEn: 'Nicaragua',
    flag: '🇳🇮',
  ),
  Country(code: 'NU', dial: '+683', name: 'Niue', nameEn: 'Niue', flag: '🇳🇺'),
  Country(
    code: 'NF',
    dial: '+672',
    name: 'Norfolk Adası',
    nameEn: 'Norfolk Island',
    flag: '🇳🇫',
  ),
  Country(
    code: 'NO',
    dial: '+47',
    name: 'Norveç',
    nameEn: 'Norway',
    flag: '🇳🇴',
  ),

  // O
  Country(
    code: 'CF',
    dial: '+236',
    name: 'Orta Afrika Cumhuriyeti',
    nameEn: 'Central African Republic',
    flag: '🇨🇫',
  ),
  Country(
    code: 'UZ',
    dial: '+998',
    name: 'Özbekistan',
    nameEn: 'Uzbekistan',
    flag: '🇺🇿',
  ),

  // P
  Country(
    code: 'PK',
    dial: '+92',
    name: 'Pakistan',
    nameEn: 'Pakistan',
    flag: '🇵🇰',
  ),
  Country(
    code: 'PW',
    dial: '+680',
    name: 'Palau',
    nameEn: 'Palau',
    flag: '🇵🇼',
  ),
  Country(
    code: 'PS',
    dial: '+970',
    name: 'Filistin',
    nameEn: 'Palestine',
    flag: '🇵🇸',
  ),
  Country(
    code: 'PA',
    dial: '+507',
    name: 'Panama',
    nameEn: 'Panama',
    flag: '🇵🇦',
  ),
  Country(
    code: 'PG',
    dial: '+675',
    name: 'Papua Yeni Gine',
    nameEn: 'Papua New Guinea',
    flag: '🇵🇬',
  ),
  Country(
    code: 'PY',
    dial: '+595',
    name: 'Paraguay',
    nameEn: 'Paraguay',
    flag: '🇵🇾',
  ),
  Country(code: 'PE', dial: '+51', name: 'Peru', nameEn: 'Peru', flag: '🇵🇪'),
  Country(
    code: 'PL',
    dial: '+48',
    name: 'Polonya',
    nameEn: 'Poland',
    flag: '🇵🇱',
  ),
  Country(
    code: 'PT',
    dial: '+351',
    name: 'Portekiz',
    nameEn: 'Portugal',
    flag: '🇵🇹',
  ),
  Country(
    code: 'PR',
    dial: '+1787',
    name: 'Porto Riko',
    nameEn: 'Puerto Rico',
    flag: '🇵🇷',
  ),

  // R
  Country(
    code: 'RE',
    dial: '+262',
    name: 'Réunion',
    nameEn: 'Réunion',
    flag: '🇷🇪',
  ),
  Country(
    code: 'RO',
    dial: '+40',
    name: 'Romanya',
    nameEn: 'Romania',
    flag: '🇷🇴',
  ),
  Country(
    code: 'RW',
    dial: '+250',
    name: 'Ruanda',
    nameEn: 'Rwanda',
    flag: '🇷🇼',
  ),
  Country(
    code: 'RU',
    dial: '+7',
    name: 'Rusya',
    nameEn: 'Russia',
    flag: '🇷🇺',
  ),

  // S
  Country(
    code: 'BL',
    dial: '+590',
    name: 'Saint Barthélemy',
    nameEn: 'Saint Barthélemy',
    flag: '🇧🇱',
  ),
  Country(
    code: 'SH',
    dial: '+290',
    name: 'Saint Helena',
    nameEn: 'Saint Helena',
    flag: '🇸🇭',
  ),
  Country(
    code: 'KN',
    dial: '+1869',
    name: 'Saint Kitts ve Nevis',
    nameEn: 'Saint Kitts and Nevis',
    flag: '🇰🇳',
  ),
  Country(
    code: 'LC',
    dial: '+1758',
    name: 'Saint Lucia',
    nameEn: 'Saint Lucia',
    flag: '🇱🇨',
  ),
  Country(
    code: 'MF',
    dial: '+590',
    name: 'Saint Martin',
    nameEn: 'Saint Martin',
    flag: '🇲🇫',
  ),
  Country(
    code: 'PM',
    dial: '+508',
    name: 'Saint Pierre ve Miquelon',
    nameEn: 'Saint Pierre and Miquelon',
    flag: '🇵🇲',
  ),
  Country(
    code: 'VC',
    dial: '+1784',
    name: 'Saint Vincent ve Grenadinler',
    nameEn: 'Saint Vincent and the Grenadines',
    flag: '🇻🇨',
  ),
  Country(
    code: 'WS',
    dial: '+685',
    name: 'Samoa',
    nameEn: 'Samoa',
    flag: '🇼🇸',
  ),
  Country(
    code: 'SM',
    dial: '+378',
    name: 'San Marino',
    nameEn: 'San Marino',
    flag: '🇸🇲',
  ),
  Country(
    code: 'ST',
    dial: '+239',
    name: 'São Tomé ve Príncipe',
    nameEn: 'São Tomé and Príncipe',
    flag: '🇸🇹',
  ),
  Country(
    code: 'SN',
    dial: '+221',
    name: 'Senegal',
    nameEn: 'Senegal',
    flag: '🇸🇳',
  ),
  Country(
    code: 'SC',
    dial: '+248',
    name: 'Seyşeller',
    nameEn: 'Seychelles',
    flag: '🇸🇨',
  ),
  Country(
    code: 'SL',
    dial: '+232',
    name: 'Sierra Leone',
    nameEn: 'Sierra Leone',
    flag: '🇸🇱',
  ),
  Country(
    code: 'SG',
    dial: '+65',
    name: 'Singapur',
    nameEn: 'Singapore',
    flag: '🇸🇬',
  ),
  Country(
    code: 'SX',
    dial: '+1721',
    name: 'Sint Maarten',
    nameEn: 'Sint Maarten',
    flag: '🇸🇽',
  ),
  Country(
    code: 'RS',
    dial: '+381',
    name: 'Sırbistan',
    nameEn: 'Serbia',
    flag: '🇷🇸',
  ),
  Country(
    code: 'SK',
    dial: '+421',
    name: 'Slovakya',
    nameEn: 'Slovakia',
    flag: '🇸🇰',
  ),
  Country(
    code: 'SI',
    dial: '+386',
    name: 'Slovenya',
    nameEn: 'Slovenia',
    flag: '🇸🇮',
  ),
  Country(
    code: 'SB',
    dial: '+677',
    name: 'Solomon Adaları',
    nameEn: 'Solomon Islands',
    flag: '🇸🇧',
  ),
  Country(
    code: 'SO',
    dial: '+252',
    name: 'Somali',
    nameEn: 'Somalia',
    flag: '🇸🇴',
  ),
  Country(
    code: 'LK',
    dial: '+94',
    name: 'Sri Lanka',
    nameEn: 'Sri Lanka',
    flag: '🇱🇰',
  ),
  Country(
    code: 'SD',
    dial: '+249',
    name: 'Sudan',
    nameEn: 'Sudan',
    flag: '🇸🇩',
  ),
  Country(
    code: 'SR',
    dial: '+597',
    name: 'Surinam',
    nameEn: 'Suriname',
    flag: '🇸🇷',
  ),
  Country(
    code: 'SY',
    dial: '+963',
    name: 'Suriye',
    nameEn: 'Syria',
    flag: '🇸🇾',
  ),
  Country(
    code: 'SA',
    dial: '+966',
    name: 'Suudi Arabistan',
    nameEn: 'Saudi Arabia',
    flag: '🇸🇦',
  ),

  // T
  Country(
    code: 'TJ',
    dial: '+992',
    name: 'Tacikistan',
    nameEn: 'Tajikistan',
    flag: '🇹🇯',
  ),
  Country(
    code: 'TZ',
    dial: '+255',
    name: 'Tanzanya',
    nameEn: 'Tanzania',
    flag: '🇹🇿',
  ),
  Country(
    code: 'TH',
    dial: '+66',
    name: 'Tayland',
    nameEn: 'Thailand',
    flag: '🇹🇭',
  ),
  Country(
    code: 'TW',
    dial: '+886',
    name: 'Tayvan',
    nameEn: 'Taiwan',
    flag: '🇹🇼',
  ),
  Country(code: 'TG', dial: '+228', name: 'Togo', nameEn: 'Togo', flag: '🇹🇬'),
  Country(
    code: 'TK',
    dial: '+690',
    name: 'Tokelau',
    nameEn: 'Tokelau',
    flag: '🇹🇰',
  ),
  Country(
    code: 'TO',
    dial: '+676',
    name: 'Tonga',
    nameEn: 'Tonga',
    flag: '🇹🇴',
  ),
  Country(
    code: 'TT',
    dial: '+1868',
    name: 'Trinidad ve Tobago',
    nameEn: 'Trinidad and Tobago',
    flag: '🇹🇹',
  ),
  Country(
    code: 'TN',
    dial: '+216',
    name: 'Tunus',
    nameEn: 'Tunisia',
    flag: '🇹🇳',
  ),
  Country(
    code: 'TC',
    dial: '+1649',
    name: 'Turks ve Caicos Adaları',
    nameEn: 'Turks and Caicos Islands',
    flag: '🇹🇨',
  ),
  Country(
    code: 'TM',
    dial: '+993',
    name: 'Türkmenistan',
    nameEn: 'Turkmenistan',
    flag: '🇹🇲',
  ),
  Country(
    code: 'TV',
    dial: '+688',
    name: 'Tuvalu',
    nameEn: 'Tuvalu',
    flag: '🇹🇻',
  ),

  // U
  Country(
    code: 'UG',
    dial: '+256',
    name: 'Uganda',
    nameEn: 'Uganda',
    flag: '🇺🇬',
  ),
  Country(
    code: 'UA',
    dial: '+380',
    name: 'Ukrayna',
    nameEn: 'Ukraine',
    flag: '🇺🇦',
  ),
  Country(
    code: 'OM',
    dial: '+968',
    name: 'Umman',
    nameEn: 'Oman',
    flag: '🇴🇲',
  ),
  Country(
    code: 'UY',
    dial: '+598',
    name: 'Uruguay',
    nameEn: 'Uruguay',
    flag: '🇺🇾',
  ),

  // V
  Country(
    code: 'VU',
    dial: '+678',
    name: 'Vanuatu',
    nameEn: 'Vanuatu',
    flag: '🇻🇺',
  ),
  Country(
    code: 'VA',
    dial: '+379',
    name: 'Vatikan',
    nameEn: 'Vatican City',
    flag: '🇻🇦',
  ),
  Country(
    code: 'VE',
    dial: '+58',
    name: 'Venezuela',
    nameEn: 'Venezuela',
    flag: '🇻🇪',
  ),
  Country(
    code: 'VN',
    dial: '+84',
    name: 'Vietnam',
    nameEn: 'Vietnam',
    flag: '🇻🇳',
  ),
  Country(
    code: 'VI',
    dial: '+1340',
    name: 'ABD Virgin Adaları',
    nameEn: 'U.S. Virgin Islands',
    flag: '🇻🇮',
  ),

  // W
  Country(
    code: 'WF',
    dial: '+681',
    name: 'Wallis ve Futuna',
    nameEn: 'Wallis and Futuna',
    flag: '🇼🇫',
  ),

  // Y
  Country(
    code: 'YE',
    dial: '+967',
    name: 'Yemen',
    nameEn: 'Yemen',
    flag: '🇾🇪',
  ),
  Country(
    code: 'NC',
    dial: '+687',
    name: 'Yeni Kaledonya',
    nameEn: 'New Caledonia',
    flag: '🇳🇨',
  ),
  Country(
    code: 'NZ',
    dial: '+64',
    name: 'Yeni Zelanda',
    nameEn: 'New Zealand',
    flag: '🇳🇿',
  ),
  Country(
    code: 'GR',
    dial: '+30',
    name: 'Yunanistan',
    nameEn: 'Greece',
    flag: '🇬🇷',
  ),

  // Z
  Country(
    code: 'ZM',
    dial: '+260',
    name: 'Zambiya',
    nameEn: 'Zambia',
    flag: '🇿🇲',
  ),
  Country(
    code: 'ZW',
    dial: '+263',
    name: 'Zimbabve',
    nameEn: 'Zimbabwe',
    flag: '🇿🇼',
  ),
];

/// Ülke kodu ile ülke bul
Country? findCountryByCode(String code) {
  try {
    return allCountries.firstWhere((c) => c.code == code);
  } catch (_) {
    return null;
  }
}

/// Alan kodu ile ülke bul
Country? findCountryByDial(String dial) {
  try {
    // +90 veya 90 formatı destekle
    final normalized = dial.startsWith('+') ? dial : '+$dial';
    return allCountries.firstWhere((c) => c.dial == normalized);
  } catch (_) {
    return null;
  }
}

/// Ülkeleri ara (isim veya alan koduna göre)
List<Country> searchCountries(String query) {
  if (query.isEmpty) return allCountries;

  final lowerQuery = query.toLowerCase();
  return allCountries.where((c) {
    return c.name.toLowerCase().contains(lowerQuery) ||
        c.nameEn.toLowerCase().contains(lowerQuery) ||
        c.dial.contains(query) ||
        c.code.toLowerCase().contains(lowerQuery);
  }).toList();
}

/// Popüler ülkeler (hızlı erişim)
List<Country> get popularCountries => [
  findCountryByCode('TR')!, // Türkiye
  findCountryByCode('US')!, // ABD
  findCountryByCode('GB')!, // UK
  findCountryByCode('DE')!, // Almanya
  findCountryByCode('FR')!, // Fransa
  findCountryByCode('NL')!, // Hollanda
  findCountryByCode('AZ')!, // Azerbaycan
  findCountryByCode('SA')!, // Suudi Arabistan
  findCountryByCode('AE')!, // BAE
  findCountryByCode('RU')!, // Rusya
];
