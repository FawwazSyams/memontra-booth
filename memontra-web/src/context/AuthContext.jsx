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
        } catch (error) {
            setUser(null);
        } finally {
            setIsLoading(false);
        }
    };

    const login = async ({ email, password, setErrors }) => {
        await csrf();
        try {
            await axios.post('/login', { email, password });
            await getUser();
            return true;
        } catch (error) {
            if (error.response?.status === 422) {
                setErrors(error.response.data.errors);
            }
            return false;
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
        getUser();
    }, []);

    return (
        <AuthContext.Provider value={{ user, isLoading, login, register, logout }}>
            {children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => useContext(AuthContext);