import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:our_community_fund/models/payment_model.dart';
import 'package:our_community_fund/models/user_model.dart';
import 'package:our_community_fund/services/payment_service.dart';
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
  final _paymentService = PaymentService();
  final _firestore = FirebaseFirestore.instance;

  UserModel? _selectedUser;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedUser = widget.selectedUser;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _recordPayment() async {
    if (_formKey.currentState!.validate() && _selectedUser != null) {
      setState(() => _isLoading = true);
      try {
        final payment = PaymentModel(
          id: '', // Will be set by Firestore
          userId: _selectedUser!.id,
          userName: _selectedUser!.name,
          amount: double.parse(_amountController.text),
          date: _selectedDate,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          recordedBy: FirebaseAuth.instance.currentUser?.email ?? 'Unknown',
        );

        await _paymentService.recordPayment(payment);
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.selectedUser == null) ...[
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .where('isAdmin', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final users = snapshot.data!.docs
                        .map((doc) => UserModel.fromFirestore(doc))
                        .toList();

                    return DropdownButtonFormField<UserModel>(
                      value: _selectedUser,
                      decoration: const InputDecoration(
                        labelText: 'Select User',
                        border: OutlineInputBorder(),
                      ),
                      items: users.map((user) {
                        return DropdownMenuItem(
                          value: user,
                          child: Text(user.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedUser = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a user';
                        }
                        return null;
                      },
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
