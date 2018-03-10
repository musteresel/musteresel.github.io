---
title: Lazy instantiation of C++ templates
date: 2018-03-09
tags: [c++, c++-templates]
language: en
...

One (tiny) piece of code that I often find useful when
meta-programming:

~~~c++
template
<
  template<class...> class T,
  typename... Args
>
struct lazy_template {
  using instantiated = T<Args...>;
};
~~~

Where does this help?  For example when there's some condition based
on which I want different types (so `std::conditional`) and these
types are templates which can only be instantiated *if* the condition
is true respective false (and otherwise result in a compiler error).

Extremely simplified example:

~~~c++
#include <type_traits>

template<typename>
struct good {
  static const bool value = true;
};

template<typename>
struct bad; // declaration only, cannot be instantiated

int main() {
  // std::conditional<good<char>, bad<int>>::type fails
  using tmpl = std::conditional<
    true,
    lazy_template<good, char>,
    lazy_template<bad, int>>::type;
  // Instantiation happens only after this point, and only for the
  // good template.
  return tmpl::instantiated::value;
}
~~~
