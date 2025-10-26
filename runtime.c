
#include <stdlib.h>
#include <stdint.h>

typedef struct {
  int32_t length;
  int32_t capacity; // default: length * 2 + 1
  int32_t *data;
} IntArray;

typedef struct {
  int32_t length;
  int32_t capacity; // default: length * 2 + 1
  double *data;
} DoubleArray;

typedef struct {
  int32_t length;
  int32_t capacity; // default: length * 2 + 1
  uint8_t *data;
} BoolArray;

typedef struct {
  int32_t length;
  int32_t capacity; // default: length * 2 + 1
  void **data;
} PtrArray;

IntArray* make_int_array(int32_t length, int32_t init_value) {
  IntArray *arr = (IntArray *)malloc(sizeof(IntArray));
  arr->length = length;
  arr->capacity = length * 2 + 1;
  arr->data = (int32_t *)malloc(arr->capacity * sizeof(int32_t));
  for (int32_t i = 0; i < length; i++) {
    arr->data[i] = init_value;
  }
  return arr;
}

DoubleArray* make_double_array(int32_t length, double init_value) {
  DoubleArray *arr = (DoubleArray *)malloc(sizeof(DoubleArray));
  arr->length = length;
  arr->capacity = length * 2 + 1;
  arr->data = (double *)malloc(arr->capacity * sizeof(double));
  for (int32_t i = 0; i < length; i++) {
    arr->data[i] = init_value;
  }
  return arr;
}

BoolArray* make_bool_array(int32_t length, uint8_t init_value) {
  BoolArray *arr = (BoolArray *)malloc(sizeof(BoolArray));
  arr->length = length;
  arr->capacity = length * 2 + 1;
  arr->data = (uint8_t *)malloc(arr->capacity * sizeof(uint8_t));
  for (int32_t i = 0; i < length; i++) {
    arr->data[i] = init_value;
  }
  return arr;
}

PtrArray* make_ptr_array(int32_t length, void *init_value) {
  PtrArray *arr = (PtrArray *)malloc(sizeof(PtrArray));
  arr->length = length;
  arr->data = (void **)malloc(length * sizeof(void *));
  for (int32_t i = 0; i < length; i++) {
    arr->data[i] = init_value;
  }
  return arr;
}

int32_t get_array_length(void *array) {
  return *((int32_t *)array);
}

void array_int_push(IntArray *arr, int32_t value) {
  if (arr->length >= arr->capacity) {
    arr->capacity = arr->capacity * 2 + 1;
    arr->data = (int32_t *)realloc(arr->data, arr->capacity * sizeof(int32_t));
  }
  arr->data[arr->length++] = value;
}

void array_double_push(DoubleArray *arr, double value) {
  if (arr->length >= arr->capacity) {
    arr->capacity = arr->capacity * 2 + 1;
    arr->data = (double *)realloc(arr->data, arr->capacity * sizeof(double));
  }
  arr->data[arr->length++] = value;
}

void array_bool_push(BoolArray *arr, uint8_t value) {
  if (arr->length >= arr->capacity) {
    arr->capacity = arr->capacity * 2 + 1;
    arr->data = (uint8_t *)realloc(arr->data, arr->capacity * sizeof(uint8_t));
  }
  arr->data[arr->length++] = value;
}

void array_ptr_push(PtrArray *arr, void *value) {
  if (arr->length >= arr->capacity) {
    arr->capacity = arr->capacity * 2 + 1;
    arr->data = (void **)realloc(arr->data, arr->capacity * sizeof(void *));
  }
  arr->data[arr->length++] = value;
}

int array_int_get(IntArray *arr, int32_t index) {
  return arr->data[index];
}

double array_double_get(DoubleArray *arr, int32_t index) {
  return arr->data[index];
}

uint8_t array_bool_get(BoolArray *arr, int32_t index) {
  return arr->data[index];
}

void* array_ptr_get(PtrArray *arr, int32_t index) {
  return arr->data[index];
}

voud array_int_put(IntArray *arr, int32_t index, int32_t value) {
  arr->data[index] = value;
}

void array_double_put(DoubleArray *arr, int32_t index, double value) {
  arr->data[index] = value;
}

void array_bool_put(BoolArray *arr, int32_t index, uint8_t value) {
  arr->data[index] = value;
}

void array_ptr_put(PtrArray *arr, int32_t index, void *value) {
  arr->data[index] = value;
}
