import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:kodepos/src/controller/kodepos_controller.dart';
import 'package:kodepos/src/model/item_address_value.dart';
import 'package:kodepos/src/style/colors.dart';
import 'package:kodepos/src/style/dimens.dart';

/// A widget that provides an input field for addresses with suggestions.
class AddressInputField extends StatefulWidget {
  final String? title;
  final String hint;
  final Widget? suffixWidget;
  final Widget? prefixWidget;
  final Widget? selectedPrefixWidget;
  final String prefixDropdownLabel;
  final int inputDelay;
  final Function(ItemAddressValue) onSelected;
  final Function onReset;
  final Color? backgroundColor;
  final List<ItemAddressValue> addressList;
  final TextEditingController addressController;
  final bool isAddressSelected;
  final InputDecoration? inputDecoration;
  final InputDecoration? inputDecorationSelected;
  final BoxDecoration? boxDecoration;
  final BoxDecoration? boxDecorationSelected;
  final bool hidePrefixOnSelected;
  final Widget? resetIcon;
  final TextStyle? textStyle;
  final TextStyle? inputTextStyle;
  final AddressDataState? addressState;

  const AddressInputField({
    super.key,
    this.title,
    this.prefixDropdownLabel = "",
    required this.addressController,
    required this.hint,
    required this.onSelected,
    required this.onReset,
    required this.isAddressSelected,
    this.hidePrefixOnSelected = false,
    this.inputDecoration,
    this.inputDecorationSelected,
    this.textStyle,
    this.boxDecoration,
    this.boxDecorationSelected,
    this.prefixWidget,
    this.selectedPrefixWidget,
    this.backgroundColor,
    this.resetIcon,
    this.inputDelay = 500,
    this.inputTextStyle,
    this.addressState,
    required this.addressList,
    this.suffixWidget,
  });

  @override
  AddressInputFieldState createState() => AddressInputFieldState();
}

class AddressInputFieldState extends State<AddressInputField> {
  final ScrollController scrollController = ScrollController();
  RxList<ItemAddressValue> addressList =
      RxList<ItemAddressValue>.empty(growable: true);
      
  Timer? _inputDelayTimer;
  bool isLoading = false;
  final RxBool isSuggestionsVisible = false.obs;

  @override
  void initState() {
    super.initState();
    widget.addressController.addListener(onChange);
    initAddress();
  }

  /// Initializes the address list with a delay to avoid lagging.
  void initAddress() async {
    await Future.delayed(const Duration(milliseconds: 100));
    addressList.addAll(widget.addressList);
  }

  /// Handles changes in the input field.
  void onChange() {
    _inputDelayTimer?.cancel();
    _inputDelayTimer = Timer(Duration(milliseconds: widget.inputDelay), () {
      getSuggestion(widget.addressController.text);
    });
  }

  /// Fetches suggestions based on the input filter.
  void getSuggestion(String filter) {
    if (!widget.isAddressSelected) {
      addressList.clear();
      if (filter.isEmpty) {
        addressList.addAll(widget.addressList);
      } else {
        addressList.addAll(widget.addressList.where((element) =>
            element.name.toLowerCase().contains(filter.toLowerCase())));
      }
      isSuggestionsVisible.value = true;
    }
  }

  /// Returns the appropriate input decoration based on the selection state.
  InputDecoration _getInputDecoration(bool isAddressSelected) {
    if (isAddressSelected) {
      return widget.inputDecorationSelected ??
          widget.inputDecoration ??
          inputTextFieldDecoration(hint: widget.hint);
    } else {
      return widget.inputDecoration ??
          inputTextFieldDecoration(hint: widget.hint);
    }
  }

  /// Returns the appropriate box decoration based on the selection state.
  BoxDecoration _getBoxDecoration(bool isSelected) {
    final defaultBoxDecoration = BoxDecoration(
      color: AppColors.instance.getBgCardWhiteColor(),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.greyBase2),
    );
    if (isSelected) {
      return widget.boxDecorationSelected ??
          widget.boxDecoration ??
          defaultBoxDecoration;
    } else {
      return widget.boxDecoration ?? defaultBoxDecoration;
    }
  }

  /// Returns the appropriate prefix widget based on the selection state and dark mode.
  Widget _getPrefixWidget({bool isDarkMode = false}) {
    final defaultPrefixWidget = Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Icon(
        Icons.search,
        color: isDarkMode ? AppColors.primayGold : AppColors.greyBase3,
      ),
    );
    if (widget.hidePrefixOnSelected && widget.isAddressSelected) {
      return Container();
    }
    if (widget.isAddressSelected) {
      return widget.selectedPrefixWidget ?? defaultPrefixWidget;
    }
    return widget.prefixWidget ?? defaultPrefixWidget;
  }

  /// Returns the appropriate reset icon based on the dark mode.
  Widget _getResetIcon({bool isDarkMode = false}) {
    return widget.resetIcon ??
        Icon(
          Icons.close,
          size: 20,
          color: isDarkMode ? AppColors.primayGold : AppColors.greyBase3,
        );
  }

  Widget _getPrefixDropdownItemWidget() {
    return Container();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return GetBuilder<KodeposController>(builder: (controller) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.title != null)
            Container(
              margin:
                  const EdgeInsets.only(bottom: AppDimens.insideHalfPadding),
              child: Text(
                widget.title!,
                style: widget.textStyle ??
                    TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.instance.getFormTitleColor(),
                    ),
              ),
            ),
          Container(
            decoration: _getBoxDecoration(widget.isAddressSelected),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _getPrefixWidget(isDarkMode: isDarkMode),
                  Expanded(
                    child: TextField(
                      enabled: !isLoading && !widget.isAddressSelected,
                      controller: widget.addressController,
                      decoration: _getInputDecoration(widget.isAddressSelected),
                      onChanged: (value) {},
                      style:
                          TextStyle(color: AppColors.instance.getTitleColor()),
                    ),
                  ),
                  if (widget.suffixWidget != null && !widget.isAddressSelected)
                    isLoading
                        ? const SizedBox(
                            width: 10,
                            height: 8,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Container(
                            margin: const EdgeInsets.only(left: 8),
                            child: widget.suffixWidget!,
                          ),
                  if (widget.isAddressSelected)
                    InkWell(
                      onTap: () {
                        isSuggestionsVisible.value = false;
                        widget.onReset();
                      },
                      child: _getResetIcon(isDarkMode: isDarkMode),
                    )
                  else
                    Obx(
                      () => InkWell(
                        onTap: () {
                          isSuggestionsVisible.value =
                              !isSuggestionsVisible.value;
                          if (isSuggestionsVisible.value) {
                            onChange();
                          }
                        },
                        child: Icon(
                          isSuggestionsVisible.value
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                          color: isDarkMode
                              ? AppColors.primayGold
                              : AppColors.greyBase3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Obx(
            () => !isSuggestionsVisible.value
                ? Container()
                : Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(16, 24, 40, 0.08),
                          blurRadius: 16,
                          spreadRadius: -4,
                          offset: Offset(0, 12),
                        ),
                      ],
                      color: AppColors.instance.getBgCardWhiteColor(),
                      borderRadius: BorderRadius.circular(12),
                      border: isDarkMode
                          ? null
                          : Border.all(color: AppColors.greyBase2),
                    ),
                    height: addressList.length > 1 ? 180 : 60,
                    child: RawScrollbar(
                      controller: scrollController,
                      thumbVisibility: true,
                      radius: const Radius.circular(50),
                      thumbColor: isDarkMode
                          ? const Color(0xFF313157)
                          : const Color(0xFFEAECF0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: ListView.builder(
                        controller: scrollController,
                        scrollDirection: Axis.vertical,
                        padding: const EdgeInsets.symmetric(horizontal: 0),
                        itemCount: addressList.length,
                        itemBuilder: (context, index) {
                          final name = addressList[index].name;
                          return InkWell(
                            onTap: () async {
                              widget.addressController.text = name;
                              widget.onSelected(addressList[index]);
                              isSuggestionsVisible.value = false;
                            },
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12, horizontal: 8),
                                  child: Row(
                                    children: [
                                      _getPrefixDropdownItemWidget(),
                                      Expanded(
                                        child: Text(
                                          widget.prefixDropdownLabel + name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.instance
                                                    .getTitleColor(),
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }

  /// Returns the input text field decoration.
  InputDecoration inputTextFieldDecoration({
    String? hint,
    Widget? icon,
    EdgeInsetsGeometry? contentPadding,
    String? counterText,
  }) =>
      InputDecoration(
        hintText: hint,
        counterText: counterText,
        hintStyle: widget.inputTextStyle ??
            TextStyle(
              color: AppColors.instance.getHintColor(),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
        icon: icon,
        fillColor: Colors.transparent,
        filled: true,
        border: InputBorder.none,
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
      );
}
