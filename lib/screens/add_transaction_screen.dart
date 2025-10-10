import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import 'settings_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final Expense? expense;
  const AddTransactionScreen({super.key, this.expense});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  final otherCategoryController = TextEditingController();
  String? category;
  DateTime selectedDate = DateTime.now();

  final List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      amountController.text = NumberFormat(
        "#,###",
      ).format(widget.expense!.amount);
      noteController.text = widget.expense!.note;
      category = widget.expense!.category;
      if (!categories.contains(category)) {
        category = 'Others';
        otherCategoryController.text = widget.expense!.category;
      }
      selectedDate = widget.expense!.date;
    }
  }

  void _saveExpense() {
    if (_formKey.currentState!.validate()) {
      String clean = amountController.text.replaceAll(',', '').trim();
      String finalCategory =
          category == 'Others' && otherCategoryController.text.isNotEmpty
          ? otherCategoryController.text
          : category!;

      final expense = Expense(
        id: widget.expense?.id ?? DateTime.now().toString(),
        amount: double.parse(clean),
        category: finalCategory,
        date: selectedDate,
        note: noteController.text,
      );

      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      if (widget.expense == null) {
        provider.addExpense(expense);
      } else {
        provider.editExpense(expense);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.expense == null ? 'Add Expense' : 'Edit Expense',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.close,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.expense == null)
            IconButton(
              icon: Icon(
                Icons.settings,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 12, right: 8),
                    child: Text(
                      '₱',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDarkMode ? Colors.white70 : Colors.grey[700],
                      ),
                    ),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 0,
                    minHeight: 0,
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter amount';
                  String clean = value
                      .replaceAll(',', '')
                      .replaceAll('₱', '')
                      .trim();
                  if (double.tryParse(clean) == null)
                    return 'Enter valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: category,
                hint: Text(
                  'Category',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                ),
                dropdownColor: isDarkMode
                    ? const Color(0xFF2C2C2C)
                    : Colors.white,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => category = val),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: isDarkMode
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) => value == null ? 'Select category' : null,
              ),
              if (category == 'Others') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: otherCategoryController,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Custom Category',
                    labelStyle: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey[700],
                    ),
                    filled: true,
                    fillColor: isDarkMode
                        ? const Color(0xFF2C2C2C)
                        : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (category == 'Others' &&
                        (value == null || value.isEmpty)) {
                      return 'Enter custom category';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: isDarkMode
                            ? ThemeData.dark().copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFF2563EB),
                                  surface: Color(0xFF1E1E1E),
                                ),
                              )
                            : ThemeData.light(),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF2C2C2C)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('yyyy-MM-dd').format(selectedDate),
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        color: isDarkMode ? Colors.white70 : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: noteController,
                maxLines: 3,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  labelText: 'Notes',
                  labelStyle: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.grey[700],
                  ),
                  alignLabelWithHint: true,
                  filled: true,
                  fillColor: isDarkMode
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                widget.expense == null ? 'Save Expense' : 'Save Changes',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String clean = newValue.text.replaceAll(',', '');
    final parsed = int.tryParse(clean);
    if (parsed == null) return oldValue;

    final newString = NumberFormat("#,###").format(parsed);
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
