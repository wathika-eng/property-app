import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ClipboardUtils {
  /// Copy text to clipboard and show a snackbar message
  static Future<void> copyToClipboard(BuildContext context, String text, {String? message}) async {
    await Clipboard.setData(ClipboardData(text: text));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? 'Copied to clipboard'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }
  
  /// Get text from clipboard
  static Future<String?> getFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      return clipboardData?.text;
    } catch (e) {
      print('Error getting clipboard data: $e');
      return null;
    }
  }
  
  /// Check if clipboard has text
  static Future<bool> hasTextInClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      return clipboardData?.text?.isNotEmpty == true;
    } catch (e) {
      print('Error checking clipboard: $e');
      return false;
    }
  }
  
  /// Copy listing share URL
  static Future<void> copyListingUrl(BuildContext context, String listingId, String title) async {
    final url = 'https://stayspace.app/listing/$listingId'; // This would be your actual app URL
    await copyToClipboard(context, url, message: 'Listing link copied');
  }
  
  /// Copy listing details for sharing
  static Future<void> copyListingDetails(BuildContext context, {
    required String title,
    required String location,
    required double price,
    required String listingId,
  }) async {
    final details = '''
$title
📍 $location
💰 \$${price.toStringAsFixed(0)}/night

Check it out: https://stayspace.app/listing/$listingId
    '''.trim();
    
    await copyToClipboard(context, details, message: 'Listing details copied');
  }
}

/// Widget to add copy functionality to any text
class CopyableText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool showCopyIcon;
  final String? copyMessage;
  
  const CopyableText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.showCopyIcon = true,
    this.copyMessage,
  });
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        ClipboardUtils.copyToClipboard(context, text, message: copyMessage);
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SelectableText(
              text,
              style: style,
              maxLines: maxLines,
            ),
          ),
          if (showCopyIcon) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                ClipboardUtils.copyToClipboard(context, text, message: copyMessage);
              },
              child: Icon(
                Icons.copy,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Enhanced TextField with paste functionality
class EnhancedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final bool enablePasteButton;
  final int? maxLines;
  
  const EnhancedTextField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.enablePasteButton = true,
    this.maxLines = 1,
  });
  
  @override
  State<EnhancedTextField> createState() => _EnhancedTextFieldState();
}

class _EnhancedTextFieldState extends State<EnhancedTextField> {
  bool _hasClipboardText = false;
  
  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }
  
  Future<void> _checkClipboard() async {
    if (widget.enablePasteButton) {
      final hasText = await ClipboardUtils.hasTextInClipboard();
      if (mounted) {
        setState(() {
          _hasClipboardText = hasText;
        });
      }
    }
  }
  
  Future<void> _pasteFromClipboard() async {
    final text = await ClipboardUtils.getFromClipboard();
    if (text != null && text.isNotEmpty) {
      widget.controller.text = text;
      if (widget.onChanged != null) {
        widget.onChanged!(text);
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      maxLines: widget.maxLines,
      validator: widget.validator,
      onChanged: (value) {
        widget.onChanged?.call(value);
        // Re-check clipboard when field changes
        if (widget.enablePasteButton) {
          _checkClipboard();
        }
      },
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.enablePasteButton && _hasClipboardText 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.suffixIcon != null) widget.suffixIcon!,
                IconButton(
                  onPressed: _pasteFromClipboard,
                  icon: const Icon(Icons.paste),
                  tooltip: 'Paste',
                ),
              ],
            )
          : widget.suffixIcon,
      ),
    );
  }
}