---
layout: post
title: "Python - How to Mock an Iterable/Iterator"
date: 2025-11-21 00:00:00 +0000
author: Ben42Code
excerpt: More complex than initially anticipated.
---

* Table of content
{:toc}

# Context

While writing unit tests, I encountered a scenario requiring mocked `Iterable`/`Iterator` to verify proper consumption of data.

And this is a quite straightforward path, except when I tried to mock an `Iterator` with `unittest.mock.MagicMock`. I'll cover each case and provide details on this tricky case.

|                            | `Iterable` | `Iterator` |
|----------------------------|------------|------------|
| `unittest.mock.MagicMock`  | Easy🟢     | Easy🟢    |
|----------------------------|------------|------------|
| `unittest.mock.MagicMock`  | Easy🟢     | **⚠️Tricky⚠️** |
{:style="width: fit-content;"}

...by ***⚠️Tricky⚠️***, I'm talking about ending up with an ***infinite recursion***!

Here is an example of what I'd like to be able to test:
```python
TODO
```

# Prerequisite

Before exploring mocks, let's define a pure `Iterable`/`Iterator` implementation. It will be easier to use those for debugging purposes, so you can put a breakpoint wherever you'd like.

### Pure Iterable

```python
class MyIterable(Iterable):
    def __init__(self, data):
        self._data = data

    def __iter__(self):
        return MyIterator(self._data)
```
### Pure Iterator

```python
class MyIterator:
    def __init__(self, data):
        self._data = data
        self._index = 0

    def __iter__(self):
        return self

    def __next__(self):
        if self._index >= len(self._data):
            raise StopIteration
        value = self._data[self._index]
        self._index += 1
        return value
```

Sanity check on expected behavior...successful✅

```python
class TestIterator(unittest.TestCase):

    ...

    def test_sanityCheck(self):
        # arrange
        data = [1, 2, 3]
        iterable = MyIterable(data)

        # act
        iterator1 = iter(iterable)
        iterator2 = iter(iterable)

        # assert
        self.assertIsInstance(iterable, MyIterable)     # ✅
        self.assertIsNot(iterator1, iterator2)          # ✅
        self.assertIsInstance(iterator1, MyIterator)    # ✅
        self.assertIsInstance(iterator2, MyIterator)    # ✅
        self.assertEqual(list(iterator1), data)         # ✅
        self.assertEqual(list(iterator2), data)         # ✅
        with self.assertRaises(StopIteration):          # ✅
            next(iterator1)
        with self.assertRaises(StopIteration):          # ✅
            next(iterator2)

    ...
```

# Iterable Mock

We'll start by mocking an `Iterable`. It's straightforward and without pitfalls.
Let's do it with a `unittest.mock.Mock` and a `unittest.mock.MagicMock`

## Mock with unittest.mock.Mock
```python
def build_IterableMock(iterable: Iterable) -> Mock:
    iterableMock = Mock(spec=['__iter__'])
    iterableMock.__iter__ = Mock(side_effect=lambda: iter(iterable))
    return iterableMock
```

### Test unittest.mock.Mock based approach
Behaves as an `Iterable`, and since it's also a Mock, we can now check if and how many times its `__iter__` method has been called. ✅

```python
class TestIterator(unittest.TestCase):

    ...

    def test_mockedIterable_withMock(self):
        # arrange
        data = [1, 2, 3]
        iterable = build_IterableMock(MyIterable(data))

        # act/assert
        self.assertEqual(iterable.__iter__.call_count, 0)   # ✅ Leveraging Mock
        iterator1 = iter(iterable)
        self.assertEqual(iterable.__iter__.call_count, 1)   # ✅ Leveraging Mock
        iterator2 = iter(iterable)
        self.assertEqual(iterable.__iter__.call_count, 2)   # ✅ Leveraging Mock

        # assert
        self.assertIsInstance(iterable, Mock)               # ✅ Confirming Mock
        self.assertIsNot(iterator1, iterator2)              # ✅
        self.assertIsInstance(iterator1, MyIterator)        # ✅
        self.assertIsInstance(iterator2, MyIterator)        # ✅
        self.assertEqual(list(iterator1), data)             # ✅
        self.assertEqual(list(iterator2), data)             # ✅
        with self.assertRaises(StopIteration):              # ✅
            next(iterator1)
        with self.assertRaises(StopIteration):              # ✅
            next(iterator2)

    ...
```

## Mock with unittest.mock.MagicMock
```python
def build_IterableMagicMock(iterable: Iterable) -> Mock:
    iterableMock = MagicMock()
    iterableMock.__iter__.side_effect = lambda: iter(iterable)
    return iterableMock
```

### Test unittest.mock.MagicMock based approach
Behaves as an `Iterable`, and since it's also a Mock, we can now check if and how many times its `__iter__` method has been called. ✅

```python
class TestIterator(unittest.TestCase):

    ...

    def test_mockedIterable_withMagicMock(self):
        # arrange
        data = [1, 2, 3]
        iterable = build_IterableMagicMock(MyIterable(data))

        # act/assert
        self.assertEqual(iterable.__iter__.call_count, 0)   # ✅ Leveraging Mock
        iterator1 = iter(iterable)
        self.assertEqual(iterable.__iter__.call_count, 1)   # ✅ Leveraging Mock
        iterator2 = iter(iterable)
        self.assertEqual(iterable.__iter__.call_count, 2)   # ✅ Leveraging Mock

        # assert
        self.assertIsInstance(iterable, MagicMock)          # ✅ Confirming MagicMock
        self.assertIsNot(iterator1, iterator2)              # ✅
        self.assertIsInstance(iterator1, MyIterator)        # ✅
        self.assertIsInstance(iterator2, MyIterator)        # ✅
        self.assertEqual(list(iterator1), data)             # ✅
        self.assertEqual(list(iterator2), data)             # ✅
        with self.assertRaises(StopIteration):              # ✅
            next(iterator1)
        with self.assertRaises(StopIteration):              # ✅
            next(iterator2)

    ...
```

# Iterator Mock

We'll now mock an `Iterator`.

We'll first implement it as a `unittest.mock.Mock`.

## Mock with unittest.mock.Mock

```python
def build_IteratorMock(side_effect) -> Mock:
    iteratorMock = Mock(spec=['__iter__', '__next__'])
    iteratorMock.__iter__ = Mock(return_value=iteratorMock)
    iteratorMock.__next__ = Mock(side_effect=side_effect)
    return iteratorMock
```

### Test unittest.mock.Mock based approach
And everything works as expected

```python
class TestIterator(unittest.TestCase):

    ...

    def test_mockedIterator_withMock(self):
        # arrange
        data = [1, 2, 3]
        iteratorMock = build_IteratorMock(MyIterable(data))

        # act/assert
        self.assertEqual(iteratorMock.__iter__.call_count, 0)   # ✅ Leveraging Mock
        self.assertEqual(iteratorMock.__next__.call_count, 0)   # ✅ Leveraging Mock
        iterator = iter(iteratorMock)
        self.assertIs(iterator, iteratorMock)                   # ✅ Confirming same iterator⚠️
        self.assertEqual(iteratorMock.__iter__.call_count, 1)   # ✅ Leveraging Mock
        self.assertEqual(iteratorMock.__next__.call_count, 0)   # ✅ Leveraging Mock

        nextValue = next(iterator)
        self.assertEqual(nextValue, 1)                          # ✅
        self.assertEqual(iteratorMock.__next__.call_count, 1)   # ✅ Leveraging Mock

        nextValue = next(iteratorMock)
        self.assertEqual(nextValue, 2)                          # ✅
        self.assertEqual(iteratorMock.__next__.call_count, 2)   # ✅ Leveraging Mock

        nextValue = next(iterator)
        self.assertEqual(nextValue, 3)                          # ✅
        self.assertEqual(iteratorMock.__next__.call_count, 3)   # ✅ Leveraging Mock

        with self.assertRaises(StopIteration):                  # ✅
            next(iterator)
        self.assertEqual(iteratorMock.__next__.call_count, 4)   # ✅ Leveraging Mock
    ...
```

## Mock with unittest.mock.MagicMock

That's when the fun starts🎉

### Naive approach

I naively though that I would apply the same pattern I used to the Iterable Mock:

```python
def build_IteratorMagicMock_naive(side_effect) -> Mock:
    iteratorMock = MagicMock()
    iteratorMock.__iter__.return_value = iteratorMock
    iteratorMock.__next__.side_effect = side_effect
    return iteratorMock
```

Except that it utterly fails and ends up in a **infinite recursion**🔴 when calling `iter` on it.

```python
data = [1, 2, 3]
iteratorMock = build_IteratorMagicMock_naive(MyIterable(data))
iterator = iter(iteratorMock)   # 🔴 Triggers an infinite recursion ⚠️
```

Here is the resulting callstack

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
The problem starts as soon as I defined the `return_value` for `__iter__`

```python
iteratorMock = MagicMock()
iteratorMock.__iter__.return_value = iteratorMock
```

Since this will endup wrapping my result into the specific function `_get_iter`. You can put a breakpoint in
[`Lib/unittest/mock.py:_set_return_value`](https://github.com/python/cpython/blob/6280bb547840b609feedb78887c6491af75548e8/Lib/unittest/mock.py#L2148-L2162), where the [`_side_effect_methods`](https://github.com/python/cpython/blob/6280bb547840b609feedb78887c6491af75548e8/Lib/unittest/mock.py#L2139-L2144) dictionary is used to leverage [`_get_iter`](https://github.com/python/cpython/blob/6280bb547840b609feedb78887c6491af75548e8/Lib/unittest/mock.py#L2121-L2128). And [`_get_iter` ends up calling `iter`](https://github.com/python/cpython/blob/6280bb547840b609feedb78887c6491af75548e8/Lib/unittest/mock.py#L2128) on the return value I provided...leading to an infinite recursive call sequence.

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




# Env

| `Python` | 3.13.3 (tags/v3.13.3:6280bb5, Apr  8 2025, 14:47:33) [MSC v.1943 64 bit (AMD64)]<br/>CPython|
| `OS`     | Windows 11<br/>25H2 (OS Build 26200.7171)<br/>26100.1.amd64fre.ge_release.240331-1435|