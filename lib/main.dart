import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Sometimes Wrong Calculator (TM)'),
          actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {},
              )
          ]
        ),
        body: Padding(
          padding: const EdgeInsets.all(18.0),
          child: SizedBox(
            width: double.infinity,
            child: CalcButton(),
          ),
        ),
      ),
    );
  }
}

class CalcButton extends StatefulWidget {
  @override
  _CalcButtonState createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton> {
  double _currentValue = 0;
  double _errorprobability = 20;
  double _errorrange = 5;
  SharedPreferences _prefs;
  static const String errorProbablityPrefKey = 'wrong_calc_probability';
  static const String errorRangePrefKey = 'wrong_calc_range';

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      setState(() => this._prefs = prefs);
      _loadProbabilityPref();
      _loadRangePref();
    });
  }


  @override
  Widget build(BuildContext context) {
    var calc = SimpleCalculator(
      value: _currentValue,
      hideExpression: false,
      hideSurroundingBorder: true,
      onChanged: (key, value, expression) {
        setState(() {
          _currentValue = value;
        });
        print("$key\t$value\t$expression");
      },
      onTappedDisplay: (value, details) {
        print("$value\t${details.globalPosition}");
      },
      errorprobability: _errorprobability / 100,
      errorrange: _errorrange / 100,
      // theme: const CalculatorThemeData(
      //   borderColor: Colors.black,
      //   borderWidth: 2,
      //   displayColor: Colors.black,
      //   displayStyle: const TextStyle(fontSize: 80, color: Colors.yellow),
      //   expressionColor: Colors.indigo,
      //   expressionStyle: const TextStyle(fontSize: 20, color: Colors.white),
      //   operatorColor: Colors.pink,
      //   operatorStyle: const TextStyle(fontSize: 30, color: Colors.white),
      //   commandColor: Colors.orange,
      //   commandStyle: const TextStyle(fontSize: 30, color: Colors.white),
      //   numColor: Colors.grey,
      //   numStyle: const TextStyle(fontSize: 50, color: Colors.white),
      // ),
    );
    return ListView(
        children: <Widget>[
            OutlineButton(
              child: Text(_currentValue.toString()),
              onPressed: () {
                showModalBottomSheet(
                    isScrollControlled: true,
                    context: context,
                    builder: (BuildContext context) {
                      return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.75,
                              child: calc);
                        });
                  },
            ),
            const Divider(),
            Text('Probability of incorrect calculation: ${_errorprobability.round().toString()} %'),
            Slider(
                value: _errorprobability,
                min: 0,
                max: 100,
                divisions: 20,
                label: '${_errorprobability.round().toString()} %',
                onChanged: (double value) {
                  setState(() {
                    _errorprobability = value;
                  });
                },
                onChangeEnd: (double value) {
                  _storeProbabilityPref(value);
                }
            ),
            const Divider(),
            Text('Error range: [-${_errorrange.round().toString()}%, +${_errorrange.round().toString()}%]'),
            Slider(
                value: _errorrange,
                min: 0,
                max: 20,
                divisions: 20,
                label: '${_errorrange.round().toString()} %',
                onChanged: (double value) {
                  setState(() {
                    _errorrange = value;
                  });
                },
                 onChangeEnd: (double value) {
                  _storeRangePref(value);
                }
            ),
        ]
    );
  }


  void _loadProbabilityPref() {
    setState(() {
      this._errorprobability = this._prefs.getDouble(errorProbablityPrefKey) ?? 20.0;
    });
  }

  Future<void> _storeProbabilityPref(double value) async {
    await this._prefs.setDouble(errorProbablityPrefKey, value);
  }

  void _loadRangePref() {
    setState(() {
      this._errorrange = this._prefs.getDouble(errorRangePrefKey) ?? 5.0;
    });
  }

  Future<void> _storeRangePref(double value) async {
    await this._prefs.setDouble(errorRangePrefKey, value);
  }

}
