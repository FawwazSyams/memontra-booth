import React, { useState, useRef, useEffect } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import logo from '../../assets/images/logo-booth-second.png';

const Navbar = () => {
    const { user, logout } = useAuth();
    const navigate = useNavigate();
    const [isDropdownOpen, setIsDropdownOpen] = useState(false);

    const handleLogout = async () => {
        await logout();
        setIsDropdownOpen(false);
        setIsMobileMenuOpen(false);
        navigate('/login');
    };
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
    const [scrolled, setScrolled] = useState(false);
    const dropdownRef = useRef(null);

    useEffect(() => {
        const handleScroll = () => {
            setScrolled(window.scrollY > 20);
        };
        window.addEventListener('scroll', handleScroll);
        return () => window.removeEventListener('scroll', handleScroll);
    }, []);

    // Close dropdown when clicked outside
    useEffect(() => {
        const handleClickOutside = (event) => {
            if (dropdownRef.current && !dropdownRef.current.contains(event.target)) {
                setIsDropdownOpen(false);
            }
        };
        document.addEventListener("mousedown", handleClickOutside);
        return () => document.removeEventListener("mousedown", handleClickOutside);
    }, []);

    const navLinks = !user ? [
        { name: 'Beranda', href: '/' },
        { name: 'Fitur', href: '/#fitur' },
        { name: 'Paket', href: '/#paket' },
        { name: 'Kontak', href: '/#kontak' },
    ] : [
        { name: 'Beranda', href: '/' },
        { name: 'Booking', href: '/booking' },
        { name: 'Riwayat', href: '/riwayat-booking' },
    ];

    return (
        <nav className={`fixed w-full z-50 transition-all duration-300 ${scrolled ? 'bg-universal shadow-[0_4px_30px_rgba(0,0,0,0.05)] py-3' : 'bg-universal/90 backdrop-blur-md py-5 border-b border-primary/5'}`}>
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex justify-between items-center">
                    {/* Logo */}
                    <div className="shrink-0 flex items-center gap-2">
                        <Link to="/" className="flex items-center group">
                            {/* Stylized premium logo text */}
                            <img src={logo} alt="Logo" className="w-40 h-auto" />
                        </Link>
                    </div>

                    {/* Desktop Menu */}
                    <div className="hidden md:flex items-center space-x-8">
                        {navLinks.map((link, index) => {
                            const isHashLink = link.href.includes('#');
                            return isHashLink ? (
                                <a
                                    key={index}
                                    href={link.href}
                                    className="text-dark/70 hover:text-primary font-semibold transition-colors relative group text-sm uppercase tracking-wider"
                                >
                                    {link.name}
                                    <span className="absolute -bottom-1.5 left-0 w-0 h-0.5 bg-primary transition-all duration-300 group-hover:w-full rounded-full"></span>
                                </a>
                            ) : (
                                <Link
                                    key={index}
                                    to={link.href}
                                    className="text-dark/70 hover:text-primary font-semibold transition-colors relative group text-sm uppercase tracking-wider"
                                >
                                    {link.name}
                                    <span className="absolute -bottom-1.5 left-0 w-0 h-0.5 bg-primary transition-all duration-300 group-hover:w-full rounded-full"></span>
                                </Link>
                            );
                        })}
                    </div>

                    {/* Right side interactions */}
                    <div className="hidden md:flex items-center space-x-4">
                        {!user ? (
                            <>
                                <Link to="/login" className="text-dark font-semibold hover:text-primary transition-colors px-4 py-2">
                                    Masuk
                                </Link>
                                <Link to="/register" className="bg-primary text-universal px-6 py-2.5 rounded-full font-bold shadow-lg shadow-primary/30 hover:shadow-primary/50 hover:-translate-y-0.5 transition-all outline-none">
                                    Daftar
                                </Link>
                            </>
                        ) : (
                            <div className="relative" ref={dropdownRef}>
                                <button
                                    onClick={() => setIsDropdownOpen(!isDropdownOpen)}
                                    className="flex items-center gap-3 focus:outline-none bg-universal hover:bg-gray-50 border border-gray-100 rounded-full pl-4 pr-1.5 py-1.5 transition-all shadow-sm hover:shadow"
                                >
                                    <span className="font-semibold text-dark text-sm max-w-[120px] truncate">
                                        Hi, {user.name.split(' ')[0]}
                                    </span>
                                    <div className="w-9 h-9 bg-linear-to-br from-primary to-primary/80 text-universal rounded-full flex items-center justify-center font-bold shadow-inner">
                                        {user.name.charAt(0).toUpperCase()}
                                    </div>
                                    <svg className={`w-4 h-4 text-dark/50 transition-transform ${isDropdownOpen ? 'rotate-180' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                                    </svg>
                                </button>

                                {/* Dropdown Menu */}
                                {isDropdownOpen && (
                                    <div className="absolute right-0 mt-4 w-72 bg-universal rounded-2xl shadow-[0_20px_60px_-15px_rgba(0,0,0,0.15)] border border-gray-100 overflow-hidden origin-top-right animate-in fade-in slide-in-from-top-4 duration-200">
                                        {/* User Info Header */}
                                        <div className="p-5 bg-linear-to-br from-primary/5 to-transparent border-b border-gray-50">
                                            <div className="flex items-center gap-4">
                                                <div className="w-12 h-12 bg-primary/10 text-primary rounded-full flex items-center justify-center font-bold text-xl border border-primary/20">
                                                    {user.name.charAt(0).toUpperCase()}
                                                </div>
                                                <div>
                                                    <p className="text-base font-bold text-dark truncate leading-tight">{user.name}</p>
                                                    <p className="text-xs text-dark/50 truncate mt-1">{user.email}</p>
                                                </div>
                                            </div>
                                        </div>

                                        {/* Navigation Links */}
                                        <div className="p-3">
                                            <Link to="/booking" onClick={() => setIsDropdownOpen(false)} className="px-4 py-3 text-sm font-semibold text-dark hover:bg-primary/5 hover:text-primary transition-all flex items-center gap-3 rounded-xl">
                                                <div className=" flex items-center justify-center text-lg"></div>
                                                Dashboard Booking
                                            </Link>
                                            <Link to="/riwayat-booking" onClick={() => setIsDropdownOpen(false)} className="px-4 py-3 text-sm font-semibold text-dark hover:bg-primary/5 hover:text-primary transition-all flex items-center gap-3 rounded-xl mt-1">
                                                <div className=" flex items-center justify-center text-lg"></div>
                                                Riwayat Pesanan
                                            </Link>
                                        </div>

                                        <div className="h-px bg-gray-100 mx-4"></div>

                                        {/* Logout Section */}
                                        <div className="p-3">
                                            <button
                                                onClick={handleLogout}
                                                className="w-full text-left px-4 py-3 text-sm text-red-500 hover:bg-red-50 font-bold transition-all flex items-center gap-3 rounded-xl"
                                            >
                                                <div className=" flex items-center justify-center text-lg"></div>
                                                Keluar
                                            </button>
                                        </div>
                                    </div>
                                )}
                            </div>
                        )}
                    </div>

                    {/* Mobile Menu Button */}
                    <div className="md:hidden flex items-center">
                        <button
                            onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                            className="bg-gray-50 text-dark hover:text-primary hover:bg-primary/5 focus:outline-none p-2 rounded-xl border border-gray-100 transition-colors"
                        >
                            <svg className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                                {isMobileMenuOpen ? (
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                                ) : (
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M4 6h16M4 12h16M4 18h16" />
                                )}
                            </svg>
                        </button>
                    </div>
                </div>
            </div>

            {/* Mobile Menu Dropdown */}
            <div className={`md:hidden absolute w-full left-0 bg-universal border-t border-gray-100 shadow-[0_20px_40px_-15px_rgba(0,0,0,0.1)] transition-all duration-300 ease-in-out origin-top ${isMobileMenuOpen ? 'scale-y-100 opacity-100' : 'scale-y-0 opacity-0'} max-h-[85vh] overflow-y-auto`}>
                <div className="px-5 py-6 space-y-2 flex flex-col">
                    {navLinks.map((link, index) => {
                        const isHashLink = link.href.includes('#');
                        return isHashLink ? (
                            <a
                                key={index}
                                href={link.href}
                                onClick={() => setIsMobileMenuOpen(false)}
                                className="text-lg font-bold text-dark/80 hover:text-primary bg-transparent hover:bg-primary/5 px-4 py-3 rounded-xl transition-all"
                            >
                                {link.name}
                            </a>
                        ) : (
                            <Link
                                key={index}
                                to={link.href}
                                onClick={() => setIsMobileMenuOpen(false)}
                                className="text-lg font-bold text-dark/80 hover:text-primary bg-transparent hover:bg-primary/5 px-4 py-3 rounded-xl transition-all"
                            >
                                {link.name}
                            </Link>
                        );
                    })}

                    <div className="pt-6 mt-2 border-t border-gray-100 flex flex-col gap-4">
                        {!user ? (
                            <>
                                <Link to="/login" className="w-full text-center border-2 border-primary/20 text-dark font-bold py-3.5 rounded-xl hover:bg-gray-50 transition-colors">
                                    Login
                                </Link>
                                <Link to="/register" className="w-full text-center bg-primary text-universal font-bold py-3.5 rounded-xl shadow-lg shadow-primary/25 hover:shadow-primary/40 transition-shadow">
                                    Mulai Sekarang
                                </Link>
                            </>
                        ) : (
                            <div className="space-y-4">
                                <div className="p-4 bg-linear-to-r from-primary/5 to-transparent rounded-2xl border border-primary/10 flex items-center gap-4">
                                    <div className="w-12 h-12 bg-primary text-universal rounded-full flex items-center justify-center font-bold text-xl shadow-sm">
                                        {user.name.charAt(0).toUpperCase()}
                                    </div>
                                    <div>
                                        <p className="font-extrabold text-dark">{user.name}</p>
                                        <p className="text-xs font-medium text-dark/50">{user.email}</p>
                                    </div>
                                </div>
                                <div className="grid grid-cols-2 gap-3">
                                    <Link to="/booking" onClick={() => setIsMobileMenuOpen(false)} className="bg-universal p-4 rounded-2xl flex flex-col items-center justify-center gap-3 border border-gray-100 shadow-sm text-dark hover:border-blue-200 hover:bg-blue-50 transition-all">
                                        <div className="w-10 h-10 bg-blue-100 text-blue-500 rounded-xl flex items-center justify-center text-xl">🎛️</div>
                                        <span className="text-sm font-bold">Dashboard</span>
                                    </Link>
                                    <Link to="/riwayat-booking" onClick={() => setIsMobileMenuOpen(false)} className="bg-universal p-4 rounded-2xl flex flex-col items-center justify-center gap-3 border border-gray-100 shadow-sm text-dark hover:border-orange-200 hover:bg-orange-50 transition-all">
                                        <div className="w-10 h-10 bg-orange-100 text-orange-500 rounded-xl flex items-center justify-center text-xl">📅</div>
                                        <span className="text-sm font-bold">Riwayat</span>
                                    </Link>
                                    <button onClick={handleLogout} className="bg-universal p-4 rounded-2xl flex flex-col items-center justify-center gap-3 border border-gray-100 shadow-sm text-red-500 hover:border-red-200 hover:bg-red-50 transition-all">
                                        <div className="w-10 h-10 bg-red-100 text-red-500 rounded-xl flex items-center justify-center text-xl"></div>
                                        <span className="text-sm font-bold">Keluar</span>
                                    </button>
                                </div>
                            </div>
                        )}
                    </div>
                </div>
            </div>
        </nav>
    );
};

export default Navbar;