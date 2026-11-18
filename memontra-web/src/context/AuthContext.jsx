// src/context/AuthContext.jsx
import React, { createContext, useContext, useState, useEffect } from 'react';
import axios from '../lib/axios';

const AuthContext = createContext({});

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [isLoading, setIsLoading] = useState(true);

    const csrf = () => axios.get('/sanctum/csrf-cookie');

    const getUser = async () => {
        try {
            const response = await axios.get('/api/user');
            setUser(response.data);
        } catch {
            setUser(null);
        } finally {
            setIsLoading(false);
        }
    };

    const login = async ({ email, password, setErrors }) => {
        await csrf();
        try {
            await axios.post('/login', { email, password });
            const response = await axios.get('/api/user');
            setUser(response.data);
            return response.data;
        } catch (error) {
            if (error.response?.status === 422) {
                setErrors(error.response.data.errors);
            } else {
                setErrors({
                    general: [error.response?.data?.message || 'Gagal masuk. Periksa email/password atau koneksi Anda.']
                });
            }
            return null;
        }
    };

    const register = async ({ name, email, password, password_confirmation, setErrors }) => {
        await csrf();
        try {
            await axios.post('/register', { name, email, password, password_confirmation });
            await getUser();
            return true;
        } catch (error) {
            if (error.response?.status === 422) {
                setErrors(error.response.data.errors);
            } else {
                setErrors({
                    general: [error.response?.data?.message || 'Gagal mendaftar. Silakan coba lagi.']
                });
            }
            return false;
        }
    };

    const logout = async () => {
        // Tambahin ini biar aman dari 419 pas logout
        await csrf();
        try {
            await axios.post('/logout');
            setUser(null);
        } catch (error) {
            console.error("Gagal logout", error);
        }
    };

    useEffect(() => {
        let isMounted = true;
        const initAuth = async () => {
            try {
                const response = await axios.get('/api/user');
                if (isMounted) setUser(response.data);
            } catch {
                if (isMounted) setUser(null);
            } finally {
                if (isMounted) setIsLoading(false);
            }
        };
        initAuth();
        return () => {
            isMounted = false;
        };
    }, []);

    return (
        <AuthContext.Provider value={{ user, isLoading, login, register, logout }}>
            {children}
        </AuthContext.Provider>
    );
};

// eslint-disable-next-line react-refresh/only-export-components
export const useAuth = () => useContext(AuthContext);