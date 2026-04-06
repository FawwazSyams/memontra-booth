// src/context/AuthContext.jsx
import React, { createContext, useContext, useState, useEffect } from 'react';
import axios from '../lib/axios';

// Membuat Context
const AuthContext = createContext({});

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [isLoading, setIsLoading] = useState(true);

    // Fungsi untuk mendapatkan CSRF Cookie dari Laravel (Wajib sebelum kirim data login/register)
    const csrf = () => axios.get('/sanctum/csrf-cookie');

    // Fungsi untuk mengambil data user yang sedang login
    const getUser = async () => {
        try {
            const response = await axios.get('/api/user');
            setUser(response.data);
        } catch (error) {
            // Jika error (misal 401 Unauthorized), berarti user belum login
            setUser(null);
        } finally {
            setIsLoading(false);
        }
    };

    // Fungsi Login
    const login = async ({ email, password, setErrors }) => {
        await csrf(); // Ambil cookie keamanan dulu
        try {
            await axios.post('/login', { email, password });
            await getUser(); // Ambil data user setelah berhasil login
            return true; // Kembalikan true jika sukses
        } catch (error) {
            if (error.response?.status === 422) {
                // Tangkap error validasi dari Laravel (misal: password salah)
                setErrors(error.response.data.errors);
            }
            return false;
        }
    };

    // Fungsi Register
    const register = async ({ name, email, password, password_confirmation, setErrors }) => {
        await csrf();
        try {
            await axios.post('/register', { name, email, password, password_confirmation });
            await getUser();
            return true;
        } catch (error) {
            if (error.response?.status === 422) {
                setErrors(error.response.data.errors);
            }
            return false;
        }
    };

    // Fungsi Logout
    const logout = async () => {
        try {
            await axios.post('/logout');
            setUser(null); // Kosongkan state user
        } catch (error) {
            console.error("Gagal logout", error);
        }
    };

    // Saat web pertama kali dibuka, langsung cek apakah user sudah login
    useEffect(() => {
        getUser();
    }, []);

    const resendVerification = async () => {
        try {
            const response = await axios.post('/email/verification-notification');
            return { success: true, message: response.data.status || 'Email verifikasi telah dikirim ulang!' };
        } catch (error) {
            return { success: false, message: 'Gagal mengirim email, coba beberapa saat lagi.' };
        }
    };

    return (
        // Jangan lupa tambahkan resendVerification ke dalam value
        <AuthContext.Provider value={{ user, isLoading, login, register, logout, resendVerification }}>
            {children}
        </AuthContext.Provider>
    );
};

// Custom Hook biar gampang dipanggil di komponen lain
export const useAuth = () => useContext(AuthContext);