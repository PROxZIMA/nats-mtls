# Purpose
This file provides guidelines for using GitHub Copilot effectively in this repository. The goal is to ensure Copilot-generated code aligns with the project's requirements, coding standards, and best practices, producing secure, maintainable, and efficient solutions.

# Usage Guidelines
## Arrays
- DO prefer collections over arrays in public APIs.
- DO NOT use read-only array fields.
- CONSIDER using jagged arrays instead of multidimensional arrays.

## Attributes
- DO name custom attribute classes with the suffix "Attribute."
- DO apply `AttributeUsageAttribute` to custom attributes.
- DO provide settable properties for optional arguments.
- DO provide get-only properties for required arguments.
- DO provide constructor parameters for required arguments.
- DO seal custom attribute classes if possible.
- DO NOT provide constructor parameters for optional arguments.
- AVOID overloading custom attribute constructors.

## Collections
- DO use the least-specialized type (e.g., `IEnumerable<T>`) for parameters.
- DO use `Collection<T>` or `ReadOnlyCollection<T>` for properties or return values.
- DO return empty collections instead of `null`.
- DO consider using subclasses of generic base collections for better naming and helper methods.
- DO consider using keyed collections if items have unique keys.
- DO NOT use weakly typed collections in public APIs.
- DO NOT use `ArrayList`, `List<T>`, `Hashtable`, or `Dictionary<TKey, TValue>` in public APIs.
- DO NOT provide settable collection properties.
- DO NOT return snapshot collections from properties; use live collections instead.
- AVOID using `ICollection<T>` or `ICollection` just to access the `Count` property.
- CONSIDER returning subclasses of `Collection<T>` or `ReadOnlyCollection<T>` for commonly used methods.
- CONSIDER using `ReadOnlyCollection<T>` for read-only collections.
- CONSIDER using `IEnumerable<T>` for forward-only iteration scenarios.

## Serialization
- DO think about serialization when designing new types.
- DO implement `IExtensibleDataObject` for backward and forward compatibility.
- DO use serialization callbacks for deserialization initialization.
- DO mark data members public if the type is used in partial trust.
- DO NOT support Runtime Serialization or XML Serialization for general persistence.
- AVOID designing types specifically for XML Serialization unless fine control over XML shape is required.
- CONSIDER supporting Data Contract Serialization for general persistence and web services.
- CONSIDER supporting XML Serialization for interoperability scenarios.
- CONSIDER using `KnownTypeAttribute` for deserializing complex object graphs.

## Equality Operators
- DO ensure `Object.Equals` and equality operators have the same semantics.
- DO overload equality operators on value types if equality is meaningful.
- DO NOT overload one equality operator without overloading the other.
- DO NOT throw exceptions from equality operators.
- AVOID overloading equality operators on mutable reference types.
- AVOID overloading equality operators on reference types if the implementation is significantly slower than reference equality.

# Designing for Extensibility
## Unsealed Classes
- CONSIDER using unsealed classes with no added virtual or protected members for inexpensive extensibility.
- DO NOT seal classes without a good reason (e.g., security, performance, or static class design).

## Protected Members
- DO treat protected members as public for security, documentation, and compatibility analysis.
- DO NOT assume protected members are secure; anyone can subclass and access them.

## Events and Callbacks
- DO prefer events over plain callbacks for familiarity and tooling support.
- DO use `Func<...>`, `Action<...>`, or `Expression<...>` instead of custom delegates for callbacks.
- DO measure performance implications when using `Expression<...>`.
- DO NOT use callbacks in performance-sensitive APIs.
- AVOID using callbacks unless necessary; prefer events for broader developer familiarity.
- CONSIDER using events to allow customization without requiring deep OOP knowledge.

## Virtual Members
- DO prefer protected accessibility over public for virtual members.
- DO NOT make members virtual unless absolutely necessary and aware of the design and maintenance costs.
- AVOID introducing virtual members unless they are critical for extensibility.
- CONSIDER limiting extensibility to only what is necessary.

## Abstractions (Abstract Types and Interfaces)
- DO choose carefully between abstract classes and interfaces when designing abstractions.
- DO NOT provide abstractions without testing them with concrete implementations and APIs.
- CONSIDER providing reference tests for concrete implementations of abstractions.
- AVOID creating too many abstractions, as they can negatively impact usability.

## Base Classes for Implementing Abstractions
- DO make base classes abstract even if they contain no abstract members.
- DO place base classes in a separate namespace for advanced extensibility scenarios.
- DO NOT name base classes with a "Base" suffix if intended for public APIs.
- AVOID using base classes unless they provide significant value to users.
- CONSIDER using delegation instead of inheritance if base classes only benefit implementers.

## Sealing
- DO seal classes if they store security-sensitive secrets, are static, or require fast runtime look-up.
- DO seal overridden members to prevent further overrides.
- DO NOT seal classes without a good reason (e.g., lack of extensibility scenarios is not a reason).
- DO NOT declare protected or virtual members on sealed types.
- CONSIDER sealing members that you override to avoid unpredictable behavior.

# Object-Orientation Abusers
## Switch Statements
- DO replace switch statements with polymorphism when dealing with type codes or multiple conditions.
- DO use Replace Type Code with Subclasses or Replace Type Code with State/Strategy for type-based switches.
- DO use Replace Conditional with Polymorphism to eliminate complex conditionals.
- DO NOT scatter switch logic across multiple places in the codebase.
- AVOID using switch statements for simple, non-repetitive actions.
- CONSIDER using Introduce Null Object if one of the conditions is null.
- CONSIDER factory patterns (e.g., Factory Method or Abstract Factory) for creating objects based on conditions.

## Temporary Field
- DO move temporary fields and related logic into a separate class using Extract Class.
- DO use Replace Method with Method Object if temporary fields are used in a complex algorithm.
- DO NOT leave fields unused or empty for most of an object’s lifecycle.
- AVOID creating fields that are only used temporarily or conditionally.
- CONSIDER using Introduce Null Object to handle conditional checks for temporary fields.

## Refused Bequest
- DO eliminate inheritance if a subclass doesn’t meaningfully use its superclass’s behavior (Replace Inheritance with Delegation).
- DO use Extract Superclass to create a shared base class if only part of the superclass is needed.
- DO NOT force inheritance solely for code reuse when classes are unrelated.
- AVOID keeping unused methods or fields in subclasses.
- CONSIDER whether inheritance is appropriate before creating a subclass.

## Alternative Classes with Different Interfaces
- DO align method names and signatures across classes with similar functionality using Rename Methods and Move Method.
- DO use Extract Superclass if classes share partial functionality.
- DO NOT maintain duplicate classes with different interfaces for the same functionality.
- AVOID creating alternative classes without checking for existing implementations.
- CONSIDER merging classes if they perform identical functions.

# Code-Generation Instructions
Use concise prompts to ensure relevant code is generated.
Review all generated code for adherence to coding standards and project-specific requirements.
Avoid generating monolithic functions; aim for modular, reusable code.

---

By adhering to these instructions, we aim to maintain high standards of quality and security across all contributions while leveraging GitHub Copilot effectively.
