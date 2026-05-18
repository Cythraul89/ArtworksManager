enum Currency {
  eur('EUR', '€'),
  usd('USD', '\$'),
  nok('NOK', 'kr'),
  zar('ZAR', 'R');

  const Currency(this.code, this.symbol);
  final String code;
  final String symbol;

  static Currency fromCode(String code) =>
      Currency.values.firstWhere((c) => c.code == code, orElse: () => Currency.eur);
}
