---
layout: post
title: "Python - Mocking Iterators and Iterables"
date: 2025-11-21 00:00:00 +0000
author: Ben42Code
excerpt: More complex than initially anticipated.
---

* Table of content
{:toc}

# Context

While writing some unit tests, I encountered a scenario requiring mocking an `Iterator` to verify proper consumption of data.
Python `Iterator` contract is available here: <https://docs.python.org/3.13/glossary.html#term-iterator>

Here is an example of what I'd like to be able to write:

```python
class TestIterator(unittest.TestCase):
    ...

    def test_mockedIterator(self):
        # arrange
        iteratorMock = build_IteratorMock([1, 2, 3])

        # act/assert
        self.assertEqual(iteratorMock.__iter__.call_count, 0)   # ✅
        iterator = iter(iteratorMock)
        self.assertIs(iterator, iteratorMock)                   # ✅ iter() on iterator returns the same iterator
        self.assertEqual(iteratorMock.__iter__.call_count, 1)   # ✅
        
        self.assertEqual(iteratorMock.__next__.call_count, 0)   # ✅

        nextValue = next(iterator)
        self.assertEqual(nextValue, 1)                          # ✅
        self.assertEqual(iteratorMock.__next__.call_count, 1)   # ✅

        nextValue = next(iteratorMock)
        self.assertEqual(nextValue, 2)                          # ✅
        self.assertEqual(iteratorMock.__next__.call_count, 2)   # ✅

        nextValue = next(iterator)
        self.assertEqual(nextValue, 3)                          # ✅
        self.assertEqual(iteratorMock.__next__.call_count, 3)   # ✅

        with self.assertRaises(StopIteration):                  # ✅
            next(iterator)
        self.assertEqual(iteratorMock.__next__.call_count, 4)   # ✅

        # assert - sanity check - no unexpected calls on __iter__
        self.assertEqual(iteratorMock.__iter__.call_count, 1)   # ✅
```

I wrote a basic implementation for this mock:

```python
def build_IteratorMock(side_effect) -> Mock:
    iteratorMock = MagicMock()
    iteratorMock.__iter__.return_value = iteratorMock   # Iterators are required to have an __iter__() method that returns the iterator object itself
    iteratorMock.__next__.side_effect = side_effect
    return iteratorMock
```

Then I tried using it, and it failed right away.😭

```python
class TestIterator(unittest.TestCase):

    ...

    def test_mockedIterator(self):
        # arrange
        data = [1, 2, 3]
        iteratorMock = build_IteratorMock(data)

        # act
        iterator = iter(iteratorMock)   # 🔴ERROR => infinite recursion occurs here

    ...
```

# Analysis / RCA

Here is the resulting callstack on test failure:

```shell
======================================================================
ERROR: test_mockedIterator_withMagicMock_naive (sandbox_basic_test.TestIterator.test_mockedIterator_withMagicMock_naive)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "d:\code\sandbox\sandbox_basic_test.py", line 171, in test_mockedIterator_withMagicMock_naive
    iterator = iter(iteratorMock)
  File "C:\Program Files\Python313\Lib\unittest\mock.py", line 1169, in __call__
    return self._mock_call(*args, **kwargs)
           ~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^
  File "C:\Program Files\Python313\Lib\unittest\mock.py", line 1173, in _mock_call
    return self._execute_mock_call(*args, **kwargs)
           ~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^
  File "C:\Program Files\Python313\Lib\unittest\mock.py", line 1234, in _execute_mock_call
    result = effect(*args, **kwargs)
  File "C:\Program Files\Python313\Lib\unittest\mock.py", line 2128, in __iter__
    return iter(ret_val)

  ... inifinite recursive sequence

  File "C:\Program Files\Python313\Lib\unittest\mock.py", line 1169, in __call__
    return self._mock_call(*args, **kwargs)
           ~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^
  File "C:\Program Files\Python313\Lib\unittest\mock.py", line 1173, in _mock_call
    return self._execute_mock_call(*args, **kwargs)
           ~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^
  File "C:\Program Files\Python313\Lib\unittest\mock.py", line 1234, in _execute_mock_call
    result = effect(*args, **kwargs)
  File "C:\Program Files\Python313\Lib\unittest\mock.py", line 2128, in __iter__
    return iter(ret_val)

  ...

RecursionError: maximum recursion depth exceeded

----------------------------------------------------------------------
Ran 1 test in 0.096s

FAILED (errors=1)
Finished running tests!
```

It's not obvious, but after spending a bit of time debugging, the problem starts as soon as I defined the `return_value` for `__iter__`:

```python
iteratorMock = MagicMock()
iteratorMock.__iter__.return_value = iteratorMock   # ⬅️Root cause of my problem🚨
```

Since defining `__iter__.return_value` will end up wrapping the result value into the private function `_get_iter` that will be the source of my problems.

You can put a breakpoint in
[`cpython/Lib/unittest/mock.py:_set_return_value`](https://github.com/python/cpython/blob/6280bb547840b609feedb78887c6491af75548e8/Lib/unittest/mock.py#L2148-L2162), where the [`_side_effect_methods`](https://github.com/python/cpython/blob/6280bb547840b609feedb78887c6491af75548e8/Lib/unittest/mock.py#L2139-L2144) dictionary is used to associate [`_get_iter`](https://github.com/python/cpython/blob/6280bb547840b609feedb78887c6491af75548e8/Lib/unittest/mock.py#L2121-L2128) to the mocked `__iter__` method. And `_get_iter` ends up calling `iter` ([here](https://github.com/python/cpython/blob/6280bb547840b609feedb78887c6491af75548e8/Lib/unittest/mock.py#L2128)) on the return value I provided...leading to an infinite recursive call sequence.

```python
def _get_iter(self):
    def __iter__():
        ret_val = self.__iter__._mock_return_value
        if ret_val is DEFAULT:
            return iter([])
        # if ret_val was already an iterator, then calling iter on it should
        # return the iterator unchanged
        return iter(ret_val)       # 🔴⚠️ <<LEADS TO INFINITE RECURSION>>
    return __iter__
```

## Step back

The `_get_iter` piece of code has been there for ages. Considering it's a regression/bug would be quite a bold assumption. Looking at the documentation, it's pretty clear that my need and expectation for `MagicMock::__iter__` are just incorrect. [The official documentation](https://docs.python.org/3.13/library/unittest.mock.html#magic-mock) provides clear examples for its usage with an `Iterable` or an `Iterator`:

> The return value of `MagicMock.__iter__()` can be any iterable object and isn’t required to be an iterator:
> 
> ```python
> >>> mock = MagicMock()
> >>> mock.__iter__.return_value = ['a', 'b', 'c']
> >>> list(mock)
> ['a', 'b', 'c']
> >>> list(mock)
> ['a', 'b', 'c']
> ```
> 
> If the return value is an iterator, then iterating over it once will consume it and subsequent iterations will result in an empty list:
> 
> ```python
> >>> mock.__iter__.return_value = iter(['a', 'b', 'c'])
> >>> list(mock)
> ['a', 'b', 'c']
> >>> list(mock)
> []
> ```

So, I'm basically misusing `MagicMock`.

But, the `MagicMock` recommendation has one big gap for my need: **`MagicMock::__next__` is not mocked and can't be mocked as is!**. So I can't directly execute the following check:

```python
self.assertEqual(iteratorMock.__next__.call_count, 2)   # Not supported as is😓
```

# Iterator Mocks Proposals

Without going into too much details, here are some options that use a vanilla `Mock` or bypass the [`_side_effect_methods`](https://github.com/python/cpython/blob/6280bb547840b609feedb78887c6491af75548e8/Lib/unittest/mock.py#L2139-L2144) custom behavior.

Based on a raw `Mock`
```python
def build_IteratorMock(side_effect) -> Mock:
    iteratorMock = Mock(spec=['__iter__', '__next__'])
    iteratorMock.__iter__ = Mock(return_value=iteratorMock)
    iteratorMock.__next__ = Mock(side_effect=side_effect)
    return iteratorMock
```

Based on a `MagicMock` and an intermediate Mock to break `MagicMock` custom behavior.
```python
def build_IteratorMock(side_effect) -> Mock:
    iteratorMock = MagicMock()
    iteratorMock.__iter__ = Mock(return_value=iteratorMock)
    iteratorMock.__next__.side_effect = side_effect
    return iteratorMock
```


Based on a `MagicMock` and a side effect that is not impacted by `MagicMock` custom behavior.
```python
def build_IteratorMock(side_effect) -> Mock:
    iteratorMock = MagicMock()
    iteratorMock.__iter__.side_effect = lambda: iteratorMock
    iteratorMock.__next__.side_effect = side_effect
    return iteratorMock
```

# Bonus - Iterable Mocks

After mocking an `Iterator`, let's also cover the `Iterable`.
Initially, let's only mock the `Iterable` part, and then we'll create a `Iterable` mock that will return `Iterator` mocks to close the loop.

## Iterable Only Mock Scope

Here is an example of what I'd like to be able to write:
```python
class TestIterator(unittest.TestCase):

    ...

    def test_mockedIterable(self):
        # arrange
        data = [1, 2, 3]
        iterableMock = build_IterableMock(data)

        # act/assert
        self.assertEqual(iterableMock.__iter__.call_count, 0)   # ✅
        iterator1 = iter(iterableMock)
        self.assertEqual(iterableMock.__iter__.call_count, 1)   # ✅
        iterator2 = iter(iterableMock)
        self.assertEqual(iterableMock.__iter__.call_count, 2)   # ✅

        # assert
        self.assertIsNot(iterator1, iterator2)                  # ✅ iter() on iterable returns a new iterator each time
        self.assertEqual(list(iterator1), data)                 # ✅
        self.assertEqual(list(iterator2), data)                 # ✅
        with self.assertRaises(StopIteration):                  # ✅
            next(iterator1)
        with self.assertRaises(StopIteration):                  # ✅
            next(iterator2)

    ...
```

## Iterable Only Mocks Proposals

Based on a raw `Mock`:
```python
def build_IterableMock(iterable: Iterable) -> Mock:
    iterableMock = Mock(spec=['__iter__'])
    iterableMock.__iter__ = Mock(side_effect=lambda: iter(iterable))
    return iterableMock
```
Based on a `MagicMock`:
```python
def build_IterableMock(iterable: Iterable) -> Mock:
    iterableMock = MagicMock()
    iterableMock.__iter__.side_effect = lambda: iter(iterable)
    return iterableMock
```

## Full Iterable Mock Scope

Here is an example of what I'd like to be able to write:

```python
class TestIterator(unittest.TestCase):

    ...
    def test_mockedFullIterable(self):
        # arrange
        data = [1, 2, 3]
        iterableMock = build_IterableMock(data)

        # act/assert
        self.assertEqual(iterableMock.__iter__.call_count, 0)   # ✅
        iteratorMock1 = iter(iterableMock)
        self.assertEqual(iterableMock.__iter__.call_count, 1)   # ✅
        iteratorMock2 = iter(iterableMock)
        self.assertEqual(iterableMock.__iter__.call_count, 2)   # ✅

        # assert - sanity checks on the iterators
        self.assertEqual(iteratorMock1.__next__.call_count, 0)  # ✅
        self.assertEqual(iteratorMock2.__next__.call_count, 0)  # ✅
        self.assertIsNot(iteratorMock1, iteratorMock2)          # ✅ iter() on iterable returns a new iterator each time

        # act/assert
        iteratorMock1_bis = iter(iteratorMock1)
        self.assertIs(iteratorMock1, iteratorMock1_bis)         # ✅ iter() on iterator returns the same iterator

        nextValue = next(iteratorMock1)
        self.assertEqual(nextValue, 1)                          # ✅
        self.assertEqual(iteratorMock1.__next__.call_count, 1)  # ✅

        nextValue = next(iteratorMock1)
        self.assertEqual(nextValue, 2)                          # ✅
        self.assertEqual(iteratorMock1.__next__.call_count, 2)  # ✅

        nextValue = next(iteratorMock1)
        self.assertEqual(nextValue, 3)                          # ✅
        self.assertEqual(iteratorMock1.__next__.call_count, 3)  # ✅

        with self.assertRaises(StopIteration):                  # ✅
            next(iteratorMock1)
        self.assertEqual(iteratorMock1.__next__.call_count, 4)  # ✅

        self.assertEqual(list(iteratorMock2), data)             # ✅
        self.assertEqual(iteratorMock2.__next__.call_count, 4)  # ✅
        with self.assertRaises(StopIteration):                  # ✅
            next(iteratorMock2)
        self.assertEqual(iteratorMock2.__next__.call_count, 5)  # ✅

```

## Full Iterable Mocks Proposals

**Disclaimer**: you need to provide/choose an implementation for `build_IteratorMock`.

Based on a raw `Mock`:
```python
def build_FullIterableMock(iterable: Iterable) -> Mock:
    iterableMock = Mock(spec=['__iter__'])
    iterableMock.__iter__ = Mock(side_effect=lambda: build_IteratorMock(iter(iterable)))
    return iterableMock
```

Based on a `MagicMock`:
```python
def build_FullIterableMock(iterable: Iterable) -> Mock:
    iterableMock = MagicMock()
    iterableMock.__iter__.side_effect = lambda: build_IteratorMock(iter(iterable))
    return iterableMock
```

# Code

All those mock implementations and their associated illustrative tests are available in this [Github Gist](https://gist.github.com/ben42code/8669a07570c73efadaa0be02d3746a3c)!

<details>
  <summary markdown="span">Sample code</summary>
  <script src="https://gist.github.com/ben42code/8669a07570c73efadaa0be02d3746a3c.js"></script>
</details>

# Env

| `Python` | 3.13.3 (tags/v3.13.3:6280bb5, Apr  8 2025, 14:47:33) [MSC v.1943 64 bit (AMD64)]<br/>CPython|
| `OS`     | Windows 11<br/>25H2 (OS Build 26200.7171)<br/>26100.1.amd64fre.ge_release.240331-1435|
{:style="width: fit-content;"}