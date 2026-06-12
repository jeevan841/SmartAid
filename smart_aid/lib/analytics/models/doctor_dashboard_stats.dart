class DoctorDashboardStats {
  final int optedInCount;
  
  // Total patients and participation rates are hidden by default for privacy compliance, 
  // but architected here for future anonymized analytics expansion.
  final String totalPatientsDisplay;
  final String participationRateDisplay;

  const DoctorDashboardStats({
    required this.optedInCount,
    this.totalPatientsDisplay = 'Hidden',
    this.participationRateDisplay = 'Hidden',
  });
}
