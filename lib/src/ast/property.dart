import 'node.dart';
import 'types.dart';

class PropertyParser {
  Node element;

  /// Checks for get or set function in full property
  final _getterOrSetterRegExp = RegExp(r'^(?:get|set)$', caseSensitive: false);

  /// Checks for get in full property
  final _getterRegExp = RegExp(r'^(?:get)$', caseSensitive: false);

  /// Checks for set function in full property
  final _setterRegExp = RegExp(r'^(?:set)$', caseSensitive: false);

  PropertyParser({
    required this.element,
  });

  /// Gets a getter or setter identifier
  Identifier? get getterOrSetter {
    final element = this.element;
    final isFunction = element.type == NodeType.functionKw;

    if (!isFunction) {
      throw Exception();
    }

    element as FunctionStatement;

    if (element.id == null) {
      // TODO: cannot find function name

      throw Exception();
    }

    final id = element.id as Identifier;

    if (!_getterOrSetterRegExp.hasMatch(id.name)) {
      // TODO: full property must has either get or set function

      return null;
    }

    return id;
  }

  /// Checks element is a getter identifier
  bool get isGetter {
    final id = getterOrSetter;

    if (id == null) {
      return false;
    }

    return _getterRegExp.hasMatch(id.name);
  }

  /// Checks element is a setter identifier
  bool get isSetter {
    final id = getterOrSetter;

    if (id == null) {
      return false;
    }

    return _setterRegExp.hasMatch(id.name);
  }
}
