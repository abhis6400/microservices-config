package com.masterclass.appa.exception;

/**
 * ============================================================
 * PHASE 4: CUSTOM BUSINESS EXCEPTION
 * ============================================================
 * 
 * PURPOSE:
 * --------
 * This exception represents BUSINESS-LEVEL errors, not technical failures.
 * 
 * EXAMPLES:
 * - "Product not found" (not a service failure, just data doesn't exist)
 * - "Invalid input" (client error, not our fault)
 * - "Insufficient funds" (business rule violation)
 * 
 * WHY THIS MATTERS FOR CIRCUIT BREAKER:
 * -------------------------------------
 * Not all exceptions should trigger the circuit breaker!
 * 
 * SHOULD trigger circuit breaker (technical failures):
 *   - IOException (network issue)
 *   - SocketTimeoutException (service not responding)
 *   - ConnectException (can't reach service)
 * 
 * SHOULD NOT trigger circuit breaker (business exceptions):
 *   - BusinessException (normal business flow)
 *   - 404 Not Found (resource doesn't exist)
 *   - 400 Bad Request (client sent wrong data)
 * 
 * If circuit breaker counted business exceptions as failures:
 *   - User searches for non-existent product → 404
 *   - Circuit breaker counts as failure ❌
 *   - After 10 searches for missing products → circuit OPENS!
 *   - ALL requests now fail! Even for existing products! 💥
 * 
 * SOLUTION:
 * Add BusinessException to `ignoreExceptions` in circuit breaker config.
 */
public class BusinessException extends RuntimeException {
    
    private final String errorCode;
    private final int httpStatus;
    
    /**
     * Create a business exception with message only.
     * 
     * @param message Human-readable error message
     */
    public BusinessException(String message) {
        super(message);
        this.errorCode = "BUSINESS_ERROR";
        this.httpStatus = 400;
    }
    
    /**
     * Create a business exception with code and message.
     * 
     * @param errorCode Machine-readable error code (e.g., "PRODUCT_NOT_FOUND")
     * @param message Human-readable error message
     */
    public BusinessException(String errorCode, String message) {
        super(message);
        this.errorCode = errorCode;
        this.httpStatus = 400;
    }
    
    /**
     * Create a business exception with code, message, and HTTP status.
     * 
     * @param errorCode Machine-readable error code
     * @param message Human-readable error message
     * @param httpStatus HTTP status code to return (400, 404, 422, etc.)
     */
    public BusinessException(String errorCode, String message, int httpStatus) {
        super(message);
        this.errorCode = errorCode;
        this.httpStatus = httpStatus;
    }
    
    /**
     * Create a business exception with cause.
     * 
     * @param message Human-readable error message
     * @param cause Original exception that caused this
     */
    public BusinessException(String message, Throwable cause) {
        super(message, cause);
        this.errorCode = "BUSINESS_ERROR";
        this.httpStatus = 400;
    }
    
    public String getErrorCode() {
        return errorCode;
    }
    
    public int getHttpStatus() {
        return httpStatus;
    }
    
    // ============================================================
    // FACTORY METHODS FOR COMMON BUSINESS EXCEPTIONS
    // ============================================================
    
    /**
     * Create a "not found" exception.
     * 
     * Example: Product with ID 12345 not found
     */
    public static BusinessException notFound(String resource, String id) {
        return new BusinessException(
            "NOT_FOUND",
            String.format("%s with ID '%s' not found", resource, id),
            404
        );
    }
    
    /**
     * Create a "validation error" exception.
     * 
     * Example: Invalid email format
     */
    public static BusinessException validationError(String field, String message) {
        return new BusinessException(
            "VALIDATION_ERROR",
            String.format("Validation failed for '%s': %s", field, message),
            400
        );
    }
    
    /**
     * Create a "conflict" exception.
     * 
     * Example: Email already registered
     */
    public static BusinessException conflict(String message) {
        return new BusinessException(
            "CONFLICT",
            message,
            409
        );
    }
    
    /**
     * Create an "unauthorized" exception.
     * 
     * Example: Invalid credentials
     */
    public static BusinessException unauthorized(String message) {
        return new BusinessException(
            "UNAUTHORIZED",
            message,
            401
        );
    }
    
    /**
     * Create a "forbidden" exception.
     * 
     * Example: User doesn't have permission
     */
    public static BusinessException forbidden(String message) {
        return new BusinessException(
            "FORBIDDEN",
            message,
            403
        );
    }
}
