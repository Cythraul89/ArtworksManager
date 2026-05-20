enum Currency {
  eur('EUR', '€'),
  usd('USD', '\$'),
  gbp('GBP', '£'),
  jpy('JPY', '¥'),
  chf('CHF', 'CHF'),
  cad('CAD', 'CA\$'),
  aud('AUD', 'A\$'),
  brl('BRL', 'BRL'),
  czk('CZK', 'CZK'),
  dkk('DKK', 'DKK'),
  hkd('HKD', 'HKD'),
  huf('HUF', 'HUF'),
  inr('INR', 'INR'),
  krw('KRW', 'KRW'),
  mxn('MXN', 'MXN'),
  nok('NOK', 'NOK'),
  nzd('NZD', 'NZD'),
  pln('PLN', 'PLN'),
  sek('SEK', 'SEK'),
  sgd('SGD', 'SGD'),
  zar('ZAR', 'ZAR');

  const Currency(this.code, this.symbol);
  final String code;
  final String symbol;

  static Currency fromCode(String code) =>
      Currency.values.firstWhere((c) => c.code == code, orElse: () => Currency.eur);
}
