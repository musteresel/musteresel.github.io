---
title: Lines of Code is a useless measurement
tags: [c, c++]
date: 2019-11-15
language: en
...

I've recently been asked how many lines of code I've written for some
project.  There are already numerous stories about why "lines of code"
is not a reasonable measurement.  Nevertheless I'd like to add my
own - a bit contrived - example.

Assuming the objective is to write a program which

 - reads integer numbers from its standard input
 - marks the numbers which are greater than 10
 - prints out in reverse order a 1 for the numbers which are marked,
   and 0 otherwise
   
I can then start off and write the following C++ program:

~~~c++
int main()
{ 
  std::vector<int> data;
  int i;
  while (std::cin >> i)
  {
    data.push_back(i);
  }
  if (!std::cin.eof())
  {
    // handle error
  }
  std::vector<bool> results;
  std::vector<int>::const_iterator it = data.begin();
  while (it != data.end())
  {
    int d = *it;
    if (d > 10)
    {
      results.push_back(true);
    }
    else
    {
      results.push_back(false);
    }
    ++it;
  }
  std::vector<bool>::reverse_iterator it2 = results.rbegin();
  while (it2 != results.rend())
  {
    std::cout << *it2 << std::endl;
    ++it2;
  }
}
~~~

This is reasonably short and can be understood fairly well.  I count
**34 lines of code**.

Of course this can also be written much more concisely:

~~~c++
int main() {
  std::vector<bool> results;
  std::transform(std::istream_iterator<int>(std::cin), std::istream_iterator<int>(),
                 std::back_inserter(results),
                 [] (int d) { return d > 10; });
  std::copy(results.rbegin(), results.rend(),
            std::ostream_iterator<bool>(std::cout, "\n"));
}
~~~

That's **8 lines of code**.

Now which is of those two versions is "better"?  The first one
requires less knowledge about the C++ standard library and can thus -
presumably - be more easily understood.  The second however is just so
much more concise that it might be better for someone who knows - and
thus understands - the used concepts from the C++ standard library.

Does the number of lines of code help in anyway?  I don't think so.
For some projects it can be beneficial to sacrifice conciseness in
order to have code that's more easily approchable for new (in general
or just new to the project) developers.  Others require concise code
to remain at least somewhat overseeable.

