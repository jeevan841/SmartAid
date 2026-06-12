import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../reports/models/patient_health_report.dart';

class PdfExportService {
  static final PdfExportService _instance = PdfExportService._internal();
  factory PdfExportService() => _instance;
  PdfExportService._internal();

  /// Orchestrates the rendering of a typed PatientHealthReport into a PDF.
  /// Zero persistence or complex data-fetching logic is allowed here.
  Future<void> generateAndSharePdf(PatientHealthReport report) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(report),
            pw.SizedBox(height: 20),
            
            _buildIntelligenceSummary(report),
            pw.SizedBox(height: 30),
            
            _buildSectionTitle('Active Medications'),
            pw.SizedBox(height: 10),
            _buildMedsTable(report),

            pw.SizedBox(height: 30),
            
            _buildSectionTitle('Upcoming Appointments'),
            pw.SizedBox(height: 10),
            _buildAppointmentsTable(report),
          ];
        },
      ),
    );

    // Convert PDF to bytes
    final Uint8List pdfBytes = await pdf.save();

    // Use printing package to share/save
    await Printing.sharePdf(
      bytes: pdfBytes, 
      filename: 'Smart_AID_Health_Report.pdf',
    );
  }

  pw.Widget _buildHeader(PatientHealthReport report) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Smart AID - Comprehensive Health Report',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated on: ${report.generatedAt.toString().split('.')[0]}',
          style: const pw.TextStyle(
            fontSize: 14,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Divider(color: PdfColors.blue900, thickness: 2),
      ],
    );
  }

  pw.Widget _buildIntelligenceSummary(PatientHealthReport report) {
    final profile = report.adherenceProfile;
    final insight = profile.dailyInsight;

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Adherence Intelligence', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.SizedBox(height: 8),
          pw.Text(insight.title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
          pw.SizedBox(height: 4),
          pw.Text(insight.message, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey800)),
          pw.SizedBox(height: 12),
          pw.Row(
            children: [
              pw.Text('Current Streak: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('${profile.consecutivePerfectDays} Days', style: const pw.TextStyle(color: PdfColors.orange700)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue800,
      ),
    );
  }

  pw.Widget _buildMedsTable(PatientHealthReport report) {
    final meds = report.activeMedications;
    if (meds.isEmpty) {
      return pw.Text('No active medications.', style: const pw.TextStyle(color: PdfColors.grey600));
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Medication Name', 'Daily Limit', 'Scheduled Times'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
      },
      data: meds.map((med) {
        return [
          med.name,
          med.dailyDoseLimit.toString(),
          med.scheduledTimes.join(', '),
        ];
      }).toList(),
    );
  }

  pw.Widget _buildAppointmentsTable(PatientHealthReport report) {
    final appointments = report.upcomingAppointments;
    if (appointments.isEmpty) {
      return pw.Text('No upcoming appointments.', style: const pw.TextStyle(color: PdfColors.grey600));
    }

    return pw.TableHelper.fromTextArray(
      headers: ['Date & Time', 'Doctor', 'Reason'],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellHeight: 30,
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
      },
      data: appointments.map((appt) {
        final dt = appt.dateTime;
        final dtString = dt != null 
            ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
            : 'Unknown';

        return [
          dtString,
          appt.doctorName,
          appt.reason,
        ];
      }).toList(),
    );
  }
}
