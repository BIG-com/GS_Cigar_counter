import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuantityInput extends StatefulWidget {
  final Function(int) onQuantitySelected;

  const QuantityInput({
    super.key,
    required this.onQuantitySelected,
  });

  @override
  State<QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<QuantityInput>
    with TickerProviderStateMixin {
  int? _selectedQuantity;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 숫자 그리드만 표시 - 애플 스타일은 즉시 반응
        _buildNumberGrid(),
      ],
    );
  }

  Widget _buildNumberGrid() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // 간단한 안내 텍스트
          Text(
            'QUANTITY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),

          // 3x4 그리드로 애플 계산기 스타일
          Column(
            children: [
              // 첫 번째 줄: 1, 2, 3
              Row(
                children: [1, 2, 3].map((number) =>
                  Expanded(child: _buildNumberButton(number))).toList(),
              ),
              const SizedBox(height: 12),
              // 두 번째 줄: 4, 5, 6
              Row(
                children: [4, 5, 6].map((number) =>
                  Expanded(child: _buildNumberButton(number))).toList(),
              ),
              const SizedBox(height: 12),
              // 세 번째 줄: 7, 8, 9
              Row(
                children: [7, 8, 9].map((number) =>
                  Expanded(child: _buildNumberButton(number))).toList(),
              ),
              const SizedBox(height: 12),
              // 네 번째 줄: 0만 가운데
              Row(
                children: [
                  const Expanded(child: SizedBox()),
                  Expanded(child: _buildNumberButton(0)),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNumberButton(int number) {
    final bool isSelected = _selectedQuantity == number;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: () {
          _selectNumber(number);
        },
        onTapDown: (_) {
          _animationController.forward();
        },
        onTapUp: (_) {
          _animationController.reverse();
        },
        onTapCancel: () {
          _animationController.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF007AFF) // iOS 시스템 블루
                      : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.08),
                      blurRadius: isSelected ? 12 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    number.toString(),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _selectNumber(int number) {
    // 햅틱 피드백
    HapticFeedback.lightImpact();

    setState(() {
      _selectedQuantity = number;
    });

    // 애플 스타일: 즉시 선택하고 콜백 호출
    widget.onQuantitySelected(number);

    // 선택 표시를 잠시 보여주고 초기화
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _selectedQuantity = null;
        });
      }
    });
  }
}

// 대안적인 심플한 수량 입력 위젯
class SimpleQuantityInput extends StatefulWidget {
  final Function(int) onQuantitySelected;
  final int? initialValue;

  const SimpleQuantityInput({
    super.key,
    required this.onQuantitySelected,
    this.initialValue,
  });

  @override
  State<SimpleQuantityInput> createState() => _SimpleQuantityInputState();
}

class _SimpleQuantityInputState extends State<SimpleQuantityInput> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            '수량 입력 (0-9)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: '0-9',
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 2,
                      ),
                    ),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                    LengthLimitingTextInputFormatter(1),
                  ],
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      final quantity = int.tryParse(value);
                      if (quantity != null && quantity >= 0 && quantity <= 9) {
                        widget.onQuantitySelected(quantity);
                      }
                    }
                  },
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      final quantity = int.tryParse(value);
                      if (quantity != null && quantity >= 0 && quantity <= 9) {
                        widget.onQuantitySelected(quantity);
                        _controller.clear();
                        _focusNode.requestFocus();
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  final value = _controller.text;
                  if (value.isNotEmpty) {
                    final quantity = int.tryParse(value);
                    if (quantity != null && quantity >= 0 && quantity <= 9) {
                      widget.onQuantitySelected(quantity);
                      _controller.clear();
                      _focusNode.requestFocus();
                    }
                  }
                },
                child: const Icon(Icons.check),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '0부터 9까지의 숫자만 입력 가능합니다',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}