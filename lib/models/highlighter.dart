import 'package:flutter/material.dart';
import '../theme/tokens.dart';

final _token = RegExp(
  r"""('(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*"|`(?:[^`\\]|\\.)*`)""" // 1 string
  r'|(\b(?:import|from|export|function|const|let|var|async|await|return|type|default|if|else|new|true|false|null|undefined)\b)' // 2 keyword
  r'|(\b(?:string|number|boolean|void|any|Props|Editor|App)\b)' // 3 type
  r'|(\b[A-Za-z_$][\w$]*)(?=\()' // 4 call
  r'|([{}()\[\];:,=.<>+\-*/])', // 5 punct
);

/// Very small tokenizer that colours one line of TS/JS using design tokens.
TextSpan highlightLine(String line, LatticeColors c, TextStyle base) {
  final spans = <TextSpan>[];
  var i = 0;
  for (final m in _token.allMatches(line)) {
    if (m.start > i) {
      spans.add(TextSpan(
          text: line.substring(i, m.start),
          style: base.copyWith(color: c.synPlain)));
    }
    Color color = c.synPlain;
    if (m.group(1) != null) {
      color = c.synString;
    } else if (m.group(2) != null) {
      color = c.synKeyword;
    } else if (m.group(3) != null) {
      color = c.synType;
    } else if (m.group(4) != null) {
      color = c.synFunction;
    } else if (m.group(5) != null) {
      color = c.synPunct;
    }
    spans.add(TextSpan(text: m.group(0), style: base.copyWith(color: color)));
    i = m.end;
  }
  if (i < line.length) {
    spans.add(TextSpan(
        text: line.substring(i), style: base.copyWith(color: c.synPlain)));
  }
  return TextSpan(children: spans, style: base);
}
