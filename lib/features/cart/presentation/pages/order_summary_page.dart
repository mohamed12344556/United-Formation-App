import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:united_formation_app/features/cart/presentation/logic/purchase_cubit.dart';
import 'package:united_formation_app/features/cart/presentation/logic/purchase_state.dart';

import '../../../../core/core.dart';
import '../../../settings/ui/cubits/profile/profile_cubit.dart';
import '../../../settings/ui/cubits/profile/profile_state.dart';
import '../../data/models/cart_model.dart';
import '../../../../generated/l10n.dart';
import 'tap_payment_screen.dart';

class OrderSummaryPage extends StatefulWidget {
  final List<CartItemModel> cartItems;
  final int subtotal;
  // final int shippingCost;
  final int totalAmount;

  const OrderSummaryPage({
    super.key,
    required this.cartItems,
    required this.subtotal,
    // required this.shippingCost,
    required this.totalAmount,
  });

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  final _formKey = GlobalKey<FormState>();

  bool get _allDigital => widget.cartItems.every(
        (item) => item.type.toLowerCase() != 'paper' && item.type != 'مطبوع',
      );
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          S.of(context).orderDetails,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<CreatePurchaseCubit, CreatePurchaseState>(
            listener: (context, state) {
              if (state is CreatePurchaseSuccess) {
                if (state.response.paymentUrl != null) {
                  log('Payment URL: ${state.response.paymentUrl}');
                  _navigateToPayment(
                    'https://tkweenstore.com/cart.php',
                  );
                } else {
                  final priceInfo = state.response.priceDetails;
                  final totalText = priceInfo != null
                      ? ' - الإجمالي: ${priceInfo.total.toStringAsFixed(2)} ر.س'
                      : '';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم إنشاء الطلب بنجاح!$totalText'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                }
              } else if (state is CreatePurchaseError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Details Form
                BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      // return _buildLoadingForm();
                      return _buildCustomerForm(isLoading: state.isLoading);
                    } else if (state.isError) {
                      return Center(
                        child: Text(
                          state.errorMessage ?? S.of(context).errorOccurred,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    } else {
                      return _buildCustomerForm(isLoading: state.isLoading);
                    }
                  },
                ),

                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),

                // Order Details
                _buildOrderDetails(),

                const SizedBox(height: 40),

                // Submit Button
                BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, state) {
                    return _buildSubmitButton(isLoading: state.isLoading);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Widget _buildCustomerForm({required bool isLoading}) {
    return Skeletonizer(
      enabled: isLoading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).customerDetails,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _nameController,
                  hintText: S.of(context).fullName,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return S.of(context).enterFullName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _emailController,
                  hintText: S.of(context).email,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return S.of(context).enterEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _phoneController,
                  hintText: S.of(context).phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return S.of(context).enterPhone;
                    }
                    if (value.trim().length < 10) {
                      return S.of(context).invalidPhoneLength;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                AppTextField(
                  controller: _addressController,
                  hintText: S.of(context).address,
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return S.of(context).enterAddress;
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingForm() {
    return Column(
      children: List.generate(3, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              height: 50,
              width: double.infinity,
              color: Colors.grey,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOrderDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          S.of(context).orderSummary,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),

        // Order items
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children:
                widget.cartItems.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price and quantity
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${S.of(context).quantity}: ${item.quantity}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              '${S.of(context).price}: ${item.unitPrice}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Book name
                        Expanded(
                          child: Text(
                            item.bookName,
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Order summary - shows tax/shipping after purchase response
        BlocBuilder<CreatePurchaseCubit, CreatePurchaseState>(
          builder: (context, state) {
            // After successful purchase, show actual price details from API
            if (state is CreatePurchaseSuccess &&
                state.response.priceDetails != null) {
              final pd = state.response.priceDetails!;
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      S.of(context).subtotal,
                      '${S.of(context).price} ${pd.subtotal.toStringAsFixed(2)}',
                    ),
                    if (pd.taxAmount > 0) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'الضريبة',
                        '${S.of(context).price} ${pd.taxAmount.toStringAsFixed(2)}',
                      ),
                    ],
                    if (pd.shippingCost > 0 && !_allDigital) ...[
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        'تكلفة الشحن',
                        '${S.of(context).price} ${pd.shippingCost.toStringAsFixed(2)}',
                      ),
                    ],
                    const SizedBox(height: 12),
                    Divider(color: Colors.grey.shade200),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      S.of(context).totalAmount,
                      '${S.of(context).price} ${pd.total.toStringAsFixed(2)}',
                      isTotal: true,
                    ),
                  ],
                ),
              );
            }

            // Default: show cart subtotal/total before purchase
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildSummaryRow(
                    S.of(context).subtotal,
                    '${S.of(context).price} ${widget.subtotal}',
                  ),
                  const SizedBox(height: 8),
                  _buildSummaryRow(
                    'الضريبة',
                    'تُحسب عند الطلب',
                  ),
                  if (!_allDigital) ...[
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'تكلفة الشحن',
                      'تُحسب عند الطلب',
                    ),
                  ],
                  const SizedBox(height: 12),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    S.of(context).totalAmount,
                    '${S.of(context).price} ${widget.totalAmount}+',
                    isTotal: true,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton({required bool isLoading}) {
    return Align(
      alignment: Alignment.center,
      child: BlocBuilder<CreatePurchaseCubit, CreatePurchaseState>(
        builder: (context, state) {
          return ElevatedButton(
            onPressed:
                state is CreatePurchaseLoading || isLoading
                    ? null
                    : _createPurchaseOrder,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 90),
              backgroundColor: isLoading ? Colors.grey : AppColors.primary,
              foregroundColor: isLoading ? Colors.grey : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                state is CreatePurchaseLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : Text(
                      S.of(context).placeOrder,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          value,
          style: TextStyle(
            color: isTotal ? AppColors.primary : Colors.black,
            fontSize: isTotal ? 18 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: isTotal ? AppColors.text : Colors.black,
            fontSize: isTotal ? 18 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _createPurchaseOrder() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final purchaseCubit = context.read<CreatePurchaseCubit>();
    final profileCubit = context.read<ProfileCubit>();
    final profile = profileCubit.state.profile;

    // Single book purchase
    await purchaseCubit.createSingleBookPurchase(
      bookId: widget.cartItems.first.bookId,
      fullName: _nameController.text.trim(),
      email: profile?.email ?? 'default@example.com',
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
    );
    // if (widget.cartItems.length == 1) {
    // } else {
    //   // Multiple books purchase
    //   final bookIds = widget.cartItems.map((item) => item.bookId).toList();
    //   final quantities = widget.cartItems.map((item) => item.quantity).toList();

    //   await purchaseCubit.createMultipleBooksPurchase(
    //     bookIds: bookIds,
    //     quantities: quantities,
    //     fullName: _nameController.text.trim(),
    //     email: profile?.email ?? 'default@example.com',
    //     phone: _phoneController.text.trim(),
    //     address: _addressController.text.trim(),
    //   );
    // }
  }

  Future<void> _loadUserProfile() async {
    final profileCubit = context.read<ProfileCubit>();
    await profileCubit.loadProfile();

    final profile = profileCubit.state.profile;
    if (profile != null) {
      _nameController.text = profile.fullName ?? '';
      _emailController.text = profile.email ?? '';
      _phoneController.text = profile.phoneNumber1 ?? '';
      _addressController.text = profile.address ?? '';
    }
  }

  // void _navigateToPayment(String paymentUrl) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder:
  //           (context) => TapPaymentScreen(
  //             tapPaymentUrl: paymentUrl,
  //             onPaymentComplete: () {
  //               // يمكن إضافة منطق ما بعد اكتمال الدفع هنا
  //               Navigator.of(context).popUntil((route) => route.isFirst);
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 const SnackBar(
  //                   content: Text('تم إنشاء الطلب بنجاح!'),
  //                   backgroundColor: Colors.green,
  //                 ),
  //               );
  //             },
  //           ),
  //     ),
  //   );
  // }

  void _navigateToPayment(String paymentUrl) {
    // تحويل بيانات السلة إلى الصيغة المطلوبة للموقع
    List<Map<String, dynamic>> cartData =
        widget.cartItems.map((item) {
          return {
            "id": item.bookId,
            "title": item.bookName,
            "image": item.imageUrl,
            "price": item.unitPrice,
            "quantity": item.quantity,
          };
        }).toList();

    // تحضير بيانات العميل
    Map<String, String> customerData = {
      "full_name": _nameController.text.trim(),
      "email": _emailController.text.trim(),
      "phone": _phoneController.text.trim(),
      "address": _addressController.text.trim(),
    };

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => TapPaymentScreen(
              tapPaymentUrl: paymentUrl,
              cartData: cartData, // تمرير بيانات السلة
              customerData: customerData, // تمرير بيانات العميل
              onPaymentComplete: () {
                // منطق ما بعد اكتمال الدفع
                Navigator.of(context).popUntil((route) => route.isFirst);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).orderCreatedSuccess),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              onPaymentCancel: () {
                // منطق إلغاء الدفع
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(S.of(context).orderPaymentCancelled),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
            ),
      ),
    );
  }
}
