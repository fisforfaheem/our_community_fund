import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:our_community_fund/data/models/user_model.dart';
import 'package:our_community_fund/domain/entities/payment.dart';
import 'package:our_community_fund/domain/use_cases/member/watch_non_admin_members_use_case.dart';
import 'package:our_community_fund/domain/use_cases/payment/payment_use_cases.dart';
import 'package:intl/intl.dart';

class RecordPaymentScreen extends StatefulWidget {
  final UserModel? selectedUser;

  const RecordPaymentScreen({super.key, this.selectedUser});

  @override
  State<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  UserModel? _selectedUser;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedUser = widget.selectedUser;
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _recordPayment() async {
    if (!_formKey.currentState!.validate() || _selectedUser == null) return;

    setState(() => _isLoading = true);
    try {
      final payment = Payment(
        id: '',
        userId: _selectedUser!.id,
        userName: _selectedUser!.name,
        amount: double.parse(_amountController.text),
        date: _selectedDate,
        note: _noteController.text.isEmpty ? null : _noteController.text,
        recordedBy: FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
      );

      await context.read<RecordPaymentUseCase>().execute(payment);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.selectedUser == null) ...[
                StreamBuilder(
                  stream: context
                      .read<WatchNonAdminMembersUseCase>()
                      .execute(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final users = snapshot.data!
                        .map(UserModel.fromEntity)
                        .toList();
                    return DropdownButtonFormField<UserModel>(
                      value: _selectedUser,
                      decoration: const InputDecoration(
                        labelText: 'Select User',
                        border: OutlineInputBorder(),
                      ),
                      items: users
                          .map((user) => DropdownMenuItem(
                                value: user,
                                child: Text(user.name),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedUser = value),
                      validator: (value) =>
                          value == null ? 'Please select a user' : null,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  if (double.parse(value) <= 0) {
                    return 'Amount must be greater than 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Payment Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('MMM dd, yyyy').format(_selectedDate)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _recordPayment,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Record Payment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}
