import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/prompt_variable.dart';

/// One fillable variable, switched by type.
///
/// Keeps its own controller so typing doesn't reset the cursor, and resyncs
/// only when the value changes for an outside reason — switching tools, or
/// a folder default being applied.
class VariableField extends StatefulWidget {
  final PromptVariable variable;
  final String value;
  final ValueChanged<String> onChanged;

  const VariableField({
    super.key,
    required this.variable,
    required this.value,
    required this.onChanged,
  });

  @override
  State<VariableField> createState() => _VariableFieldState();
}

class _VariableFieldState extends State<VariableField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(covariant VariableField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text && widget.value != old.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = widget.variable;
    final constraintNote = v.constraints.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              v.type.icon,
              size: 15,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                v.label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '{{${v.key}}}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (!v.required) ...[
              const SizedBox(width: 6),
              Text(
                'optional',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          v.help,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        _buildInput(context),
        const SizedBox(height: 4),
        Text(
          constraintNote == null
              ? 'Example: ${v.example}'
              : 'Example: ${v.example} · $constraintNote',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildInput(BuildContext context) {
    final v = widget.variable;
    switch (v.type) {
      case VariableType.enumChoice:
        final current = v.options.contains(widget.value) ? widget.value : null;
        return DropdownButtonFormField<String>(
          initialValue: current,
          hint: Text(v.example),
          items: [
            for (final o in v.options)
              DropdownMenuItem(value: o, child: Text(o)),
          ],
          onChanged: (value) => widget.onChanged(value ?? ''),
        );

      case VariableType.number:
        return TextField(
          controller: _controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(hintText: v.example),
          onChanged: widget.onChanged,
        );

      case VariableType.color:
        return TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: v.example,
            prefixIcon: Padding(
              padding: const EdgeInsets.all(12),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _parseColor(
                    widget.value.isNotEmpty ? widget.value : v.example,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
            ),
          ),
          onChanged: widget.onChanged,
        );

      // Real file pickers arrive with the backend. Until then these take a
      // filename so the preview and JSON export are complete and correct.
      case VariableType.image:
      case VariableType.imageList:
      case VariableType.assetRef:
        return TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: v.example,
            prefixIcon: Icon(v.type.icon),
          ),
          onChanged: widget.onChanged,
        );

      case VariableType.text:
        return TextField(
          controller: _controller,
          maxLength: v.constraints.maxLength,
          maxLines: null,
          decoration: InputDecoration(hintText: v.example, counterText: ''),
          onChanged: widget.onChanged,
        );
    }
  }

  Color _parseColor(String hex) {
    var h = hex.trim().replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(int.tryParse(h, radix: 16) ?? 0xFF9E9E9E);
  }
}
