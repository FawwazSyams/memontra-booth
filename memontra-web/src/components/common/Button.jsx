import React from 'react';

// Membuat komponen tombol yang bisa dikustomisasi warna dan ukurannya
const Button = ({ children, variant = 'primary', className = '', ...props }) => {
    const baseClasses = "px-6 py-3 rounded-full font-semibold transition-all duration-300 transform hover:scale-105 focus:outline-none";

    // Menentukan warna berdasarkan prop 'variant' menggunakan warna kustom kamu
    const variants = {
        primary: "bg-primary text-universal hover:bg-opacity-90",
        secondary: "bg-secondary text-dark hover:bg-opacity-90",
        outline: "border-2 border-primary text-primary hover:bg-primary hover:text-universal",
    };

    return (
        <button className={`${baseClasses} ${variants[variant]} ${className}`} {...props}>
            {children}
        </button>
    );
};

export default Button;