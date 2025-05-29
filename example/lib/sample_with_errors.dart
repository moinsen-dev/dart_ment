// This file contains various linting errors for testing dart_ment fix command

class SampleClass {
  // prefer_final_fields
  String name = 'test';

  // unnecessary_this
  void setName(String newName) {
    this.name = newName;
  }

  // avoid_print
  void debugLog(String message) {
    print('Debug: $message');
  }

  // prefer_single_quotes
  String getMessage() {
    return "Hello World";
  }

  // unnecessary_new
  Object createObject() {
    return new Object();


  // prefer_const_constructors
  buildWidget() {
    return Container();
  }
}

// sort_constructors_first
class User {
  void doSomething() {}

  User(name);

  final String name;
}

// missing documentation
class Widget {}

class Container extends Widget {}
