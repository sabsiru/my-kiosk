import 'package:flutter/material.dart';
import '../../models/cart_item.dart';
import '../../models/menu.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';

class OptionSelector extends StatefulWidget {
  final MenuDetail menuDetail;
  final ValueChanged<CartItem> onConfirm;

  const OptionSelector({
    super.key,
    required this.menuDetail,
    required this.onConfirm,
  });

  @override
  State<OptionSelector> createState() => _OptionSelectorState();
}

class _OptionSelectorState extends State<OptionSelector> {
  final Map<String, List<MenuOptionItem>> _selectedOptions = {};
  int _quantity = 1;

  int get _optionPrice {
    int total = 0;
    for (final items in _selectedOptions.values) {
      for (final item in items) {
        total += item.additionalPrice;
      }
    }
    return total;
  }

  int get _totalPrice =>
      (widget.menuDetail.price + _optionPrice) * _quantity;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.menuDetail.name,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              if (widget.menuDetail.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(widget.menuDetail.description,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                ),
              const SizedBox(height: 8),
              Text(
                '${_formatPrice(widget.menuDetail.price)}원',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Divider(),

              // 옵션 목록
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: widget.menuDetail.options.length,
                  itemBuilder: (context, index) {
                    final option = widget.menuDetail.options[index];
                    return _buildOptionGroup(option);
                  },
                ),
              ),

              const Divider(),

              // 수량 + 담기 버튼
              Row(
                children: [
                  // 수량 조절
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        SizedBox(
                          width: 32,
                          child: Text('$_quantity',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => setState(() => _quantity++),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _canConfirm() ? _confirm : null,
                        child: Text(
                          '${_formatPrice(_totalPrice)}원 담기',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionGroup(MenuOption option) {
    final selected = _selectedOptions[option.name] ?? [];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(option.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              if (option.isRequired)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text('필수',
                      style:
                          TextStyle(fontSize: 12, color: AppColors.error)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ...option.items.map((item) {
            final isSelected = selected.any((s) => s.id == item.id);
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(item.name, style: const TextStyle(fontSize: 15)),
              trailing: item.additionalPrice > 0
                  ? Text('+${_formatPrice(item.additionalPrice)}원',
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.textSecondary))
                  : null,
              leading: option.maxSelection == 1
                  ? Radio<int>(
                      value: item.id,
                      groupValue: selected.isNotEmpty ? selected.first.id : null,
                      onChanged: (_) {
                        setState(() {
                          _selectedOptions[option.name] = [item];
                        });
                      },
                    )
                  : Checkbox(
                      value: isSelected,
                      onChanged: (_) {
                        setState(() {
                          if (isSelected) {
                            _selectedOptions[option.name] =
                                selected.where((s) => s.id != item.id).toList();
                          } else if (selected.length < option.maxSelection) {
                            _selectedOptions[option.name] = [...selected, item];
                          }
                        });
                      },
                    ),
              onTap: () {
                if (option.maxSelection == 1) {
                  setState(() {
                    _selectedOptions[option.name] = [item];
                  });
                }
              },
            );
          }),
        ],
      ),
    );
  }

  bool _canConfirm() {
    for (final option in widget.menuDetail.options) {
      if (option.isRequired) {
        final selected = _selectedOptions[option.name] ?? [];
        if (selected.isEmpty) return false;
      }
    }
    return true;
  }

  void _confirm() {
    widget.onConfirm(CartItem(
      menuId: widget.menuDetail.id,
      menuName: widget.menuDetail.name,
      unitPrice: widget.menuDetail.price,
      quantity: _quantity,
      selectedOptions: _selectedOptions,
      optionAdditionalPrice: _optionPrice,
    ));
  }

  String _formatPrice(int price) {
    return price.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
