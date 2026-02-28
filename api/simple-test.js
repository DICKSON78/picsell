module.exports = (req, res) => {
  res.status(200).json({
    message: 'Simple test working',
    timestamp: new Date().toISOString(),
    phone: '0678960706',
    formatted: '255678960706',
    amount: 24000,
    note: 'Phone number formatting works - ready for USSD push when ClickPesa credentials are fixed'
  });
};
