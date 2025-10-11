import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw; // ← Fixed: removed extra quote
import 'dart:io';
import '../providers/expense_provider.dart';

class ExportService {
  Future<void> exportToCSV(BuildContext context) async {
    final expenses = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    ).expenses;

    List<List<dynamic>> rows = [
      ['Date', 'Category', 'Amount', 'Note'],
      ...expenses.map(
        (e) => [
          e.date.toIso8601String(),
          e.category,
          e.amount.toString(),
          e.note,
        ],
      ),
    ];

    String csv = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csv);

    await Share.shareXFiles([XFile(file.path)], text: 'My Expenses');
  }

  Future<void> exportToPDF(BuildContext context) async {
    final expenses = Provider.of<ExpenseProvider>(
      context,
      listen: false,
    ).expenses;

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Expense Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: ['Date', 'Category', 'Amount', 'Note'],
                data: expenses
                    .map(
                      (e) => [
                        e.date.toString().split(' ')[0],
                        e.category,
                        '₱${e.amount.toStringAsFixed(2)}',
                        e.note,
                      ],
                    )
                    .toList(),
              ),
            ],
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}/expenses_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles([XFile(file.path)], text: 'My Expenses Report');
  }
}
