import 'package:flutter/material.dart';

import '../../../../core/core.dart';
import '../../domain/entities/user_order_entity.dart';

class OrderItemCard extends StatelessWidget {
  final UserOrderEntity order;
  final VoidCallback? onTap;
  final bool isResponsive;
  const OrderItemCard({
    super.key,
    required this.order,
    this.onTap,
    this.isResponsive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomMargin =
        isResponsive ? (context.isTablet ? 20.h : 16.h) : 16.0;
    final cardBorderRadius = isResponsive ? 16.r : 16.0;

    return Container(
      margin: EdgeInsets.only(bottom: bottomMargin),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCardHeader(context),
              _buildBooksSection(context),
              if (order.priceSummary != null) _buildPriceSummary(context),
              _buildCardFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
      ),
      child: Row(
        children: [
          // Order icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.receipt_long,
              color: AppColors.primary,
              size: isResponsive ? (context.isTablet ? 28.r : 24.r) : 24,
            ),
          ),
          const SizedBox(width: 12),
          // Order info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طلب #${order.id}',
                  style: TextStyle(
                    fontSize:
                        isResponsive ? (context.isTablet ? 16.sp : 14.sp) : 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        order.formattedDate,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: isResponsive
                              ? (context.isTablet ? 14.sp : 12.sp)
                              : 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    if (order.payment != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.credit_card,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${order.payment!.method}${order.payment!.lastFour != null ? ' •••• ${order.payment!.lastFour}' : ''}',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isResponsive
                                ? (context.isTablet ? 14.sp : 12.sp)
                                : 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(order.status).withOpacity(0.15),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              order.statusText,
              style: TextStyle(
                color: _getStatusColor(order.status),
                fontSize:
                    isResponsive ? (context.isTablet ? 14.sp : 12.sp) : 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBooksSection(BuildContext context) {
    if (order.books.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          order.title,
          style: TextStyle(
            fontSize:
                isResponsive ? (context.isTablet ? 16.sp : 14.sp) : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: order.books.map((book) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.book,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        style: TextStyle(
                          fontSize: isResponsive
                              ? (context.isTablet ? 16.sp : 14.sp)
                              : 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'الكمية: ${book.quantity}',
                        style: TextStyle(
                          fontSize: isResponsive
                              ? (context.isTablet ? 14.sp : 12.sp)
                              : 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${book.total.toStringAsFixed(2)} ر.س',
                  style: TextStyle(
                    fontSize: isResponsive
                        ? (context.isTablet ? 16.sp : 14.sp)
                        : 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceSummary(BuildContext context) {
    final ps = order.priceSummary!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildPriceRow(context, 'المجموع الفرعي', ps.subtotal),
          if (ps.taxAmount > 0)
            _buildPriceRow(context, 'الضريبة', ps.taxAmount),
          if (ps.shippingCost > 0)
            _buildPriceRow(context, 'الشحن', ps.shippingCost),
          const Divider(height: 16),
          _buildPriceRow(context, 'الإجمالي', ps.total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.text : AppColors.textSecondary,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} ر.س',
            style: TextStyle(
              fontSize: isTotal ? 14 : 12,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? AppColors.primary : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            _getStatusIcon(order.status),
            size: 16,
            color: _getStatusColor(order.status),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getStatusMessage(order.status),
              style: TextStyle(
                fontSize: isResponsive
                    ? (context.isTablet ? 14.sp : 12.sp)
                    : 12,
                color: Colors.grey[600],
              ),
            ),
          ),
          if (order.shipping != null)
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  order.shipping!.methodName,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.orange;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return Icons.hourglass_bottom;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.processing:
        return 'جاري تجهيز طلبك';
      case OrderStatus.shipped:
        return 'طلبك في الطريق إليك';
      case OrderStatus.delivered:
        return 'تم توصيل طلبك بنجاح';
      case OrderStatus.cancelled:
        return 'تم إلغاء الطلب';
    }
  }
}
