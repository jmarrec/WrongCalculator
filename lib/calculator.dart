// Copyright 2019 zuvola. All rights reserved.

import 'package:expressions/expressions.dart';
import 'package:intl/intl.dart';
import 'dart:math';

bool isInteger(num value) {
  return (value is int || value == value.roundToDouble());
}

/// Display value for the [Calculator].
class CalcDisplay {
  String string;
  double value = 0;

  /// The [NumberFormat] used for display
  final NumberFormat numberFormat;

  /// Maximum number of digits on display.
  final int maximumDigits;

  CalcDisplay(this.numberFormat, this.maximumDigits) {
    clear();
  }

  /// Add a digit to the display.
  void addDigit(int digit) {
    var reg = RegExp(
        "[${numberFormat.symbols.GROUP_SEP}${numberFormat.symbols.DECIMAL_SEP}]");
    if (string.replaceAll(reg, "").length >= maximumDigits) {
      return;
    }
    if (string == numberFormat.symbols.ZERO_DIGIT) {
      string = numberFormat.format(digit);
    } else {
      string += numberFormat.format(digit);
    }
    _reformat();
  }

  /// Add a decimal point.
  void addPoint() {
    if (string.contains(numberFormat.symbols.DECIMAL_SEP)) {
      return;
    }
    string += numberFormat.symbols.DECIMAL_SEP;
  }

  /// Clear value to zero.
  void clear() {
    string = numberFormat.symbols.ZERO_DIGIT;
    value = 0;
  }

  /// Remove the last digit.
  void removeDigit() {
    if (string.length == 1 ||
        (string.startsWith(numberFormat.symbols.MINUS_SIGN) &&
            string.length == 2)) {
      clear();
    } else {
      string = string.substring(0, string.length - 1);
      _reformat();
    }
  }

  /// Set the value.
  void setValue(double val) {
    value = val;
    string = numberFormat.format(val);
  }

  /// Toggle between a plus sign and a minus sign.
  void toggleSign() {
    if (value <= 0) {
      string = string.replaceFirst(numberFormat.symbols.MINUS_SIGN, "");
    } else {
      string = numberFormat.symbols.MINUS_SIGN + string;
    }
    _reformat();
  }

  /// Check the validity of the displayed value.
  bool validValue() {
    return !(string == numberFormat.symbols.NAN ||
        string == numberFormat.symbols.INFINITY);
  }

  void _reformat() {
    value = numberFormat.parse(string);
    if (!string.contains(numberFormat.symbols.DECIMAL_SEP)) {
      string = numberFormat.format(value);
    }
  }
}

/// Expression for the [Calculator].
class CalcExpression {
  final ExpressionEvaluator evaluator = const ExpressionEvaluator();
  final String zeroDigit;

  String value = "";
  String internal = "";
  String _op;
  String _right;
  String _rightInternal;
  String _left;
  String _lefInternal;

  /// Create a [CalcExpression] with [zeroDigit].
  CalcExpression({this.zeroDigit = "0"});

  void clear() {
    value = "";
    internal = "";
    _op = null;
    _right = null;
    _left = null;
    _lefInternal = null;
    _rightInternal = null;
  }

  bool needClearDisplay() {
    return _op != null && _right == null;
  }

  /// Perform operations.
  num operate() {
    try {
      return evaluator.eval(Expression.parse(internal), null);
    } catch (e) {
      print(e);
    }
    return double.nan;
  }

  void repeat(CalcDisplay val) {
    if (_right != null) {
      _left = value = val.string;
      _lefInternal = internal = val.value.toString();
      value = "$_left $_op $_right";
      internal = "$_lefInternal${_convertOperator()}$_rightInternal";
      val.setValue(operate());
    }
  }

  /// Set the operation. The [op] must be either +, -, ×, or ÷.
  void setOperator(String op) {
    if (_left == null) {
      _left = _lefInternal = zeroDigit;
    }
    if (_right != null) {
      _left = "$_left $_op $_right";
      _lefInternal = "$_lefInternal${_convertOperator()}$_rightInternal";
      _right = _rightInternal = null;
    }
    _op = op;
    value = "$_left $_op ?";
  }

  /// Set percent value. The [string] is a string representation and [percent] is a value.
  double setPercent(String string, double percent) {
    var base = 1.0;
    if (_op == "+" || _op == "-") {
      base = evaluator.eval(Expression.parse(_lefInternal), null);
    }
    var val = base * percent / 100;
    if (_op == null) {
      _left = value = string;
      _lefInternal = internal = val.toString();
      return val;
    } else {
      _right = string;
      _rightInternal = val.toString();
      value = "$_left $_op $_right";
      internal = "$_lefInternal${_convertOperator()}$val";
      return val;
    }
  }

  /// Set value with [CalcDisplay].
  void setVal(CalcDisplay val) {
    if (_op == null) {
      _left = value = val.string;
      _lefInternal = internal = val.value.toString();
    } else {
      _right = val.string;
      _rightInternal = val.value.toString();
      value = "$_left $_op $_right";
      internal = "$_lefInternal${_convertOperator()}$_rightInternal";
    }
  }

  String _convertOperator() {
    return _op.replaceFirst("×", "*").replaceFirst("÷", "/");
  }
}

/// Calculator
class Calculator {
  final randomGenerator = new Random();
  final CalcExpression _expression;
  final CalcDisplay _display;
  bool _operated = false;

  /// The [NumberFormat] used for display
  final NumberFormat numberFormat;

  /// Maximum number of digits on display.
  final int maximumDigits;

  /// Create a [Calculator] with [maximumDigits] is 10 and maximumFractionDigits of [numberFormat] is 6.
  Calculator({maximumDigits = 10})
      : this.numberFormat(
            NumberFormat()..maximumFractionDigits = 6, maximumDigits);

  /// Create a [Calculator].
  Calculator.numberFormat(this.numberFormat, this.maximumDigits)
      : _expression =
            CalcExpression(zeroDigit: numberFormat.symbols.ZERO_DIGIT),
        _display = CalcDisplay(numberFormat, maximumDigits);

  /// Display string
  get displayString => _display.string;

  /// Display value
  get displayValue => _display.value;

  /// Expression
  get expression => _expression.value;

  /// Set the value.
  void setValue(double val) {
    _display.setValue(val);
    _expression.setVal(_display);
  }

  /// Add a digit to the display.
  void addDigit(int digit) {
    if (!_display.validValue()) {
      return;
    }
    if (_expression.needClearDisplay()) {
      _display.clear();
    }
    if (_operated) {
      allClear();
    }
    _display.addDigit(digit);
    _expression.setVal(_display);
  }

  /// Add a decimal point.
  void addPoint() {
    if (!_display.validValue()) {
      return;
    }
    if (_expression.needClearDisplay()) {
      _display.clear();
    }
    if (_operated) {
      allClear();
    }
    _display.addPoint();
    _expression.setVal(_display);
  }

  /// Clear all entries.
  void allClear() {
    _expression.clear();
    _display.clear();
    _expression.setVal(_display);
    _operated = false;
  }

  /// Clear last entry.
  void clear() {
    _display.clear();
    _expression.setVal(_display);
  }

  /// Perform operations.
  void operate({bool add_error = false}) {
    if (!_display.validValue()) {
      return;
    }
    if (_operated) {
      _expression.repeat(_display);
    } else {
      // TODO: HERE!
      num result = _expression.operate();
      print("original result=$result");
      if (add_error) {
        // We're going to introduce errors in the calculation!

        // 1 in 6 chances of having a mistake
        if (randomGenerator.nextInt(5) == 3) {
          print("Let's make it wrong!");
          // nextDouble € [0,1]
          // Shift that to [-0.5, 0.5]
          // Then we divide by 10 and multiply by result, to get [-5%, +5%]
          double offset = result * (randomGenerator.nextDouble() - 0.5) / 10.0;
          print('offset: $offset');
          // If integer, then use an integer error
          if (isInteger(result)) {
            int int_offset = offset.round();
            print("int_offset=$int_offset");
            if (int_offset == 0) {
              // Force not having zero as mistake
              // x / x.abs() => return +1 or -1
              offset = offset / offset.abs();
              print('offset forced to $offset');
            } else {
              offset = offset.toDouble();
            }
          } else {
            // Avoid having too many extra digits after decimal separator
            int len_tot = result.toString().length;
            int len_int = result.round().toString().length;
            int precision = len_tot - len_int - 1;
            print("len=$len_tot, len_int=$len_int, precision=$precision");
            offset = num.parse(offset.toStringAsFixed(precision));
          }
          result= result + offset;
        }
      }
      _display.setValue(result);
    }
    _operated = true;
  }

  /// Remove the last digit.
  void removeDigit() {
    if (_check()) return;
    _display.removeDigit();
    _expression.setVal(_display);
  }

  /// Set the operation. The [op] must be either +, -, ×, or ÷.
  void setOperator(String op) {
    if (_check()) return;
    _expression.setOperator(op);
    if (op == "+" || op == "-") {
      operate();
      _operated = false;
    }
  }

  /// Set a percent sign.
  void setPercent() {
    if (_check()) return;
    var string = _display.string + numberFormat.symbols.PERCENT;
    var val = _expression.setPercent(string, _display.value);
    _display.setValue(val);
  }

  /// Toggle between a plus sign and a minus sign.
  void toggleSign() {
    if (_check()) return;
    _display.toggleSign();
    _expression.setVal(_display);
  }

  ///
  bool _check() {
    if (!_display.validValue()) {
      return true;
    }
    if (_operated) {
      _expression.clear();
      _expression.setVal(_display);
      _operated = false;
    }
    return false;
  }
}
